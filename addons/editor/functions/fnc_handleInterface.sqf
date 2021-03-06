/*
 * Author: SilentSpike, Kingsley
 * Handles editor interface events
 *
 * Arguments:
 * 0: Event name <STRING>
 * 1: Event arguments <ANY>
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * ["onLoad", _this] call mars_editor_fnc_handleInterface;
 *
 * Public: No
 */

#include "script_component.hpp"

params ["_mode", ["_args", []]];

switch (toLower _mode) do {
    case "onload": {
        _args params ["_display"];

        SETUVAR(GVAR(interface), _display);
        SETUVAR(GVAR(cursorHelper), (_display displayCtrl IDC_CURSORHELPER));

        // [] call FUNC(createEntityList);
        [_display] call FUNC(createAssetBrowser);
        [_display] call FUNC(createMenuStrip);
        [_display] call FUNC(createToolbar);

        // Status Bar
        [_display] call FUNC(handleStatusBar);
        [{params ["_display"];[_display] call FUNC(handleCompass);}, 0, _display] call CBA_fnc_addPerFrameHandler;

        // Invoke the default right-panel state
        ["rightModes", [controlNull, GVAR(abCurrentMode)]] call FUNC(handlePanelSections);

        GVAR(delayedPFH) = [{
            private _display = GETUVAR(GVAR(interface),displayNull);
            (_display displayCtrl IDC_STATUSBAR_FPS) ctrlSetText format ["%1 FPS", round GVAR(fps_server)];
            (_display displayCtrl IDC_STATUSBAR_GRID) ctrlSetText format ["%1", mapGridPosition GVAR(camera)];
        }, 1, []] call CBA_fnc_addPerFrameHandler;
        GVAR(pfhArray) pushBackUnique GVAR(delayedPFH);

        // Set the cursor to default
        [] call FUNC(setCursor);

        // Disable and hide map
        _map = _display displayCtrl IDC_MAP;
        _map ctrlShow false;
        _map ctrlEnable false;
        
        // Initialize map
        [_display, _map] call FUNC(handleMap);

        // Disable search controls
        {(_display displayCtrl _x) ctrlEnable false} forEach [
            IDC_ASSETBROWSER_SEARCH_CREATE,
            IDC_ASSETBROWSER_SEARCH_CREATE_BTN,
            IDC_LEFTPANEL_EDIT_SEARCH,
            IDC_LEFTPANEL_EDIT_SEARCHBTN
        ];
        
        // Add panel toggle event handlers
        (_display displayCtrl IDC_LEFTPANEL_TAB_TOGGLE) ctrlAddEventHandler ["ButtonClick", {["toggleLeftPanel", _this] call FUNC(handleInterface)}];
        (_display displayCtrl IDC_ASSETBROWSER_TOGGLE) ctrlAddEventHandler ["ButtonClick", {["toggleRightPanel", _this] call FUNC(handleInterface)}];

        // Set vehicle crew checkbox
        private _vehicleCrewCheckBox = _display displayCtrl IDC_VEHICLE_TOGGLE;
        _vehicleCrewCheckBox cbSetChecked ([QGVAR(placeVehiclesWithCrew), true] call CFUNC(loadSetting));

        [_display] call FUNC(serializeIcons);
    };
    case "onunload": {
        // Kill GUI PFHs
        GVAR(camHandler) = nil;

        // Reset variables
        GVAR(camBoom) = 0;
        GVAR(camDolly) = [0,0];
        GVAR(ctrlKey) = false;
        GVAR(shiftKey) = false;
        GVAR(altKey) = false;
        GVAR(heldKeys) = [];
        GVAR(heldKeys) resize 255;
        GVAR(mouse) = [false,false];
        GVAR(mousePos) = [0.5,0.5];
        
        [] call FUNC(killPerFrameHandlers);
    };
    case "onmousebuttondown": {
        _args params ["_ctrl","_button"];
        GVAR(mouse) set [_button,true];

        if ((_button == 0) && {GVAR(canContext)}) then {
            [GVAR(ctrlKey)] call FUNC(placeNewObject);
            GVAR(prepDragObjectUnderCursor) = GVAR(objectUnderCursor);
            GVAR(prepDirObjectUnderCursor) = GVAR(objectUnderCursor);
        };

        // Detect right click
        if ((_button == 1) && {(GVAR(camMode) == 1)}) then {
            // In first person toggle sights mode
            // Is this needed?
            [] call FUNC(transitionCamera);
        };
    };
    case "onmousebuttonup": {
        _args params ["_ctrl","_button"];

        private _wasContextOpen = GVAR(contextMenuOpen);

        GVAR(mouse) set [_button,false];
        [] call FUNC(closeContextMenu);

        if (GVAR(isDragging)) then {
            if (GVAR(prepDragObjectUnderCursor) != GVAR(objectDragAnchor)) then {
                GVAR(allowDragging) = false;
                [objNull, false, true] call FUNC(handleLeftDrag);
            } else {
                [GVAR(objectDragAnchor), true, true] call FUNC(handleLeftDrag);
            };
        };

        if (GVAR(isDirection)) then {
            if (GVAR(prepDirObjectUnderCursor) != GVAR(objectDirAnchor)) then {
                GVAR(allowDirection) = false;
                [objNull, false, true] call FUNC(handleSelectionDir);
            } else {
                [GVAR(objectDirAnchor), true, true] call FUNC(handleSelectionDir);
            };
        };

        switch (true) do {
            // Left Click
            case (_button == 0 && !GVAR(canContext)): {
                // GVAR(camDolly) = [0,0];
            };

            // Left Click & Can Context
            case (_button == 0 && GVAR(canContext)): {
                if (!GVAR(hoveringOverGroupIcon)) then {
                    [] call FUNC(selectObject);
                };
            };

            // Right Click
            case (_button == 1 && !GVAR(canContext)): {};

            // Right Click & Can Context
            case (_button == 1 && GVAR(canContext)): {
                if (!(GVAR(selection) isEqualTo []) && {GVAR(abSelectedObject) isEqualTo []} && {!GVAR(isWaitingForLeftClick)} && {!_wasContextOpen}) then {
                    // systemChat "Already has objects in selection";
                    private _target = GVAR(objectUnderCursor);

                    if (_target in GVAR(selection)) then {
                        [] call FUNC(handleContextMenu);
                    } else {
                        if (!isNull _target) then {
                            [] call FUNC(closeContextMenu);
                            [] call FUNC(handleSelToPos);
                        } else {
                            private _cursorWorldPos = AGLtoASL (screenToWorld GVAR(mousePos));
                            _cursorWorldPos resize 2;

                            if (
                                {(_cursorWorldPos distance2D _x) < 10} count GVAR(selection) > 0 ||
                                {GVAR(hoveringOverGroupIcon)}
                            ) then {
                                [] call FUNC(handleContextMenu);
                            } else {
                                [] call FUNC(closeContextMenu);
                                [] call FUNC(handleSelToPos);
                            };
                        };
                    };
                } else {
                    // systemChat "No objects in selection, proceed to handle context menu";
                    [] call FUNC(selectObject);
                    [] call FUNC(handleContextMenu);
                };

                [{
                    [{
                        [] call FUNC(killRightClickPenders);
                    }, []] call EFUNC(common,execNextFrame);
                }, []] call EFUNC(common,execNextFrame);
            };
        };

        if (_button == 0) then {
            // This is used for context options that require a position
            if (GVAR(isWaitingForLeftClick)) then {
                GVAR(hasLeftClicked) = true;
            };
        };

        GVAR(prepDragObjectUnderCursor) = objNull;
        GVAR(objectDragAnchor) = objNull;

        // This needs to be executed 2 frames later
        [{
            [{
                if (!isNil QGVAR(selectionDirPFH)) then {
                    [GVAR(selectionDirPFH)] call CBA_fnc_removePerFrameHandler;
                };
            }, []] call EFUNC(common,execNextFrame);
            
            if (GVAR(isSelectionBoxSpawned)) then {
                ["end"] call FUNC(handleSelectionBox);
            };
        }, []] call EFUNC(common,execNextFrame);
    };
    case "onmousezchanged": {
        _args params ["_ctrl","_zChange"];
        if (true) exitWith {false};
    };
    case "onmousemoving": {
        _args params ["_ctrl","_x","_y"];

        if (GVAR(mouse) select 1) then {
            GVAR(canContext) = false;
        };
        
        if ((GVAR(mouse) select 1) && {!GVAR(canContext)}) then {
            [] call FUNC(setCursor);
        };

        if (!isNull GVAR(prepDragObjectUnderCursor) && {(GVAR(mouse) select 0)} && {GVAR(canContext)} && {!GVAR(shiftKey)} && {!GVAR(ctrlKey)}) then {
            GVAR(allowDragging) = true;
            [GVAR(objectDragAnchor)] call FUNC(handleLeftDrag);
        };

        if ((GVAR(mouse) select 0) && {GVAR(canContext)} && {GVAR(shiftKey)} && {!GVAR(ctrlKey)}) then {
            GVAR(allowDirection) = true;
            [GVAR(objectDirAnchor)] call FUNC(handleSelectionDir);
        };

        if (
            (GVAR(mouse) select 0) &&
            {GVAR(canContext)} &&
            {!GVAR(shiftKey)} &&
            {!GVAR(ctrlKey)} &&
            {isNull GVAR(objectDragAnchor)} &&
            {isNull GVAR(objectDirAnchor)} &&
            {!EGVAR(attributes,isOpen)}
        ) then {
            [["update","init"] select !GVAR(isSelectionBoxSpawned)] call FUNC(handleSelectionBox);
        };

        [_x, _y] call FUNC(handleMouse);
    };
    case "onmouseholding": {
        _args params ["_ctrl","_x","_y"];

        if !(GVAR(mouse) select 1) then {
            GVAR(canContext) = true;
        };

        if (!isNull GVAR(prepDragObjectUnderCursor) && {(GVAR(mouse) select 0)} && {GVAR(canContext)} && {!GVAR(shiftKey)} && {!GVAR(ctrlKey)}) then {
            [GVAR(objectDragAnchor)] call FUNC(handleLeftDrag);
        };

        if ((GVAR(mouse) select 0) && {GVAR(canContext)} && {GVAR(shiftKey)} && {!GVAR(ctrlKey)}) then {
            [GVAR(objectDirAnchor)] call FUNC(handleSelectionDir);
        };
    };
    case "onkeydown": {
        _args params ["_display","_dik","_shift","_ctrl","_alt"];

        if (!GVAR(shiftKey)) then {GVAR(shiftKey) = _shift};
        if (!GVAR(ctrlKey)) then {GVAR(ctrlKey) = _ctrl};

        // Handle held keys (prevent repeat calling)
        if (GVAR(heldKeys) param [_dik,false]) exitWith {};
        // Exclude movement/adjustment keys so that speed can be adjusted on fly
        if !(_dik in [16,17,30,31,32,44,74,78]) then {
            GVAR(heldKeys) set [_dik,true];
        };

        switch (_dik) do {
            case DIK_ESCAPE: { // Esc
                // [QGVAR(escape)] call FUNC(interrupt);
                // ["escape"] call FUNC(handleInterface);
                [player] call FUNC(shutdown);
            };
            case DIK_DELETE: { // Delete
                [] call FUNC(deleteSelection);
            };
            case DIK_1: { // 1
            };
            case DIK_2: { // 2
            };
            case DIK_3: { // 3
            };
            case DIK_4: { // 4
            };
            case DIK_5: { // 5
            };
            case DIK_BACK: { // Backspace
            };
            case DIK_Q: { // Q
                GVAR(camBoom) = 0.5 * GVAR(camSpeed) * ([1, CAM_SHIFT_SPEED_COEF] select _shift);
            };
            case DIK_W: { // W
                GVAR(camDolly) set [1, GVAR(camSpeed) * ([1, CAM_SHIFT_SPEED_COEF] select _shift)];
            };
            case DIK_LCONTROL: { // Ctrl
                GVAR(ctrlKey) = true;
            };
            case DIK_A: { // A
                GVAR(camDolly) set [0, -GVAR(camSpeed) * ([1, CAM_SHIFT_SPEED_COEF] select _shift)];
            };
            case DIK_S: { // S
                GVAR(camDolly) set [1, -GVAR(camSpeed) * ([1, CAM_SHIFT_SPEED_COEF] select _shift)];
            };
            case DIK_D: { // D
                GVAR(camDolly) set [0, GVAR(camSpeed) * ([1, CAM_SHIFT_SPEED_COEF] select _shift)];
            };
            case DIK_Z: { // Z
                GVAR(camBoom) = -0.5 * GVAR(camSpeed) * ([1, CAM_SHIFT_SPEED_COEF] select _shift);
            };
            case DIK_N: { // N
                [!GVAR(nightVisionEnabled)] call FUNC(toggleNightVision);
            };
            case DIK_M: { // M
                private _map = _display displayCtrl IDC_MAP;
                private _newState = !(ctrlShown _map);
                [_newState] call FUNC(openMap);
            };
            case DIK_E:  { // E
                ["toggleLeftPanel", _this] call FUNC(handleInterface);
            };
            case DIK_R:  { // R
                ["toggleRightPanel", _this] call FUNC(handleInterface);
            };
            case DIK_SPACE: { // Spacebar
            };
            case DIK_SUBTRACT: { // Num -
            };
            case DIK_ADD: { // Num +
            };
            case DIK_UP: { // Up arrow
            };
            case DIK_LEFT: { // Left arrow
            };
            case DIK_RIGHT: { // Right arrow
            };
            case DIK_DOWN: { // Down arrow
            };
            case DIK_F1: { // F1
            };
            case DIK_F2: { // F2
            };
            case DIK_F3: { // F3
            };
            case DIK_F4: { // F4
            };
            case DIK_F5: { // F5
            };
            case DIK_L: { // L
                // Light
                [] call FUNC(toggleLight);
            };
        };

        true
    };
    case "onkeyup": {
        _args params ["_display","_dik","_shift","_ctrl","_alt"];

        // systemChat str _dik;

        if (!isNil QGVAR(selectionDirPFH)) then {
            [GVAR(selectionDirPFH)] call CBA_fnc_removePerFrameHandler;
        };

        if (GVAR(shiftKey)) then {GVAR(shiftKey) = _shift};
        if (GVAR(ctrlKey)) then {GVAR(ctrlKey) = _ctrl};

        // No longer being held
        GVAR(heldKeys) set [_dik,nil];

        switch (_dik) do {
            case 207: { // End
                [] call FUNC(destroySelection);
            };
            case 16: { // Q
                GVAR(camBoom) = 0;
            };
            case 17: { // W
                GVAR(camDolly) set [1, 0];
            };
            case 29: { // Ctrl
                GVAR(ctrlKey) = false;
            };
            case 42: { // Shift
                GVAR(shiftKey) = false;
            };
            case 30: { // A
                GVAR(camDolly) set [0, 0];
            };
            case 31: { // S
                GVAR(camDolly) set [1, 0];
            };
            case 32: { // D
                GVAR(camDolly) set [0, 0];
            };
            case 44: { // Z
                GVAR(camBoom) = 0;
            };
            case 13: { // +
                if (!isMultiplayer) then {
                    setAccTime 4;
                };
            };
            case 12: { // -
                if (!isMultiplayer) then {
                    setAccTime 1;
                };
            };
        };

        true
    };
    case "onmapclick": {
        _args params ["_map","_button","_x","_y","_shift","_ctrl","_alt"];
    };
    case "escape": {
    };
    case "toggleleftpanel": {
        private _display = GETUVAR(GVAR(interface),displayNull);
        
        {
            private _control = _display displayCtrl _x;
            _control ctrlSetFade ([1,0] select (ctrlFade _control > 0));
            _control ctrlCommit 0;
        } forEach [IDC_LEFTPANEL_TAB_BG, IDC_LEFTPANEL_TAB_SECTIONS, IDC_LEFTPANEL_BG, IDC_LEFTPANEL_EDIT, IDC_LEFTPANEL_LOCS];
    };
    case "togglerightpanel": {
        private _display = GETUVAR(GVAR(interface),displayNull);
        
        {
            private _control = _display displayCtrl _x;
            _control ctrlSetFade ([1,0] select (ctrlFade _control > 0));
            _control ctrlCommit 0;
        } forEach [IDC_ASSETBROWSER_SECTIONS_BG, IDC_ASSETBROWSER_SECTIONS, IDC_ASSETBROWSER_BG, IDC_ASSETBROWSER_NOTES, IDC_ASSETBROWSER_CREATE];
    };
};
