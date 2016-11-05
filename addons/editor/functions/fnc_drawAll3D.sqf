/*
 * Author: Kingsley
 * Draws all icons/lines needed in 3D space
 * Called every frame from openEditor
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call mars_editor_fnc_drawAll3D;
 *
 * Public: No
 */

#include "script_component.hpp"

BEGIN_COUNTER(drawAll3D);

private _camPosASL = GVAR(camPos);
GVAR(groupIcons) = [];
GVAR(unitIcons) = [];

private _rendered = 0;

{
    _x params [
        "_object",
        ["_icon", ""],
        ["_color", [0,0,0,0]],
        ["_zOffset", 0],
        ["_shadow", 1],
        ["_isGroupMarker", false],
        ["_fixedDistance", GVAR(iconDrawDistance)],
        ["_cursorScale", 0.033],
        ["_displayText", ""]
    ];

    private _pos = (getPosASLVisual _object) vectorAdd [0, 0, _zOffset];
    private _alpha = linearConversion [0, _fixedDistance, (_pos distance _camPosASL), 1, 0, true];
    private _width = 1;
    private _height = 1;

    if (_isGroupMarker) then {
        GVAR(groupIcons) pushBack [ASLtoAGL _pos, group _object];

        if (_object in GVAR(selection)) then {
            _alpha = 1;
            _width = GVAR(iconHoverSize);
            _height = GVAR(iconHoverSize);
        } else {
            if (_alpha > 0.25) then {
                private _iconScreenPos = worldToScreen (ASLtoAGL _pos);

                if (!(_iconScreenPos isEqualTo []) && {(_iconScreenPos distance2D GVAR(mousePos)) <= _cursorScale}) then {
                    _alpha = 1;
                    _width = GVAR(iconHoverSize);
                    _height = GVAR(iconHoverSize);
                    ["select"] call FUNC(setCursor);
                };
            };
        };
    } else {
        GVAR(unitIcons) pushBack [ASLtoAGL _pos, _object];
    };

    _color set [3, [_alpha, 1] select (_object in GVAR(selection))];

    drawIcon3D [
        _icon,
        _color,
        ASLtoAGL _pos,
        _width,
        _height,
        0,
        _displayText,
        _shadow,
        0.031
    ];

    _rendered = _rendered + 1;

    false
} count GVAR(serializedIcons);

systemChat format ["Drew %1 / %2 Entities", _rendered, count GVAR(serializedIcons)];

END_COUNTER(drawAll3D);