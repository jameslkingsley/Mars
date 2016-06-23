/*
 * Author: Kingsley
 * Sends in the selected units as reinforcements using the chosen method
 *
 * Arguments:
 * Attributes controls <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * N/A
 *
 * Public: No
 */

#include "script_component.hpp"

private _unitSelection = [_this, 'Basic_PlayerList_Control'] call AFUNC(getControlValue);
private _insertionMethod = ([_this, 'Basic_InsertionMethod_Control'] call AFUNC(getControlValue)) param [1, "teleport"];
private _paraHeight = [_this, 'Basic_ParaHeight_Control'] call AFUNC(getControlValue);
private _paraRadius = [_this, 'Basic_ParaRadius_Control'] call AFUNC(getControlValue);
private _destination = [_this, 'Basic_Destination_Control'] call AFUNC(getControlValue);

private _configureGroup = [_this, 'Advanced_AdvancedToggle_Control'] call AFUNC(getControlValue);
private _groupLeader = ([_this, 'Advanced_GroupLeader_Control'] call AFUNC(getControlValue)) param [1, ""];
private _groupLeaderObject = (allPlayers select {(getPlayerUID _x) == _groupLeader}) param [0, objNull];
private _groupName = [_this, 'Advanced_GroupDetails_Name'] call AFUNC(getControlValue);
private _groupColor = ([_this, 'Advanced_GroupDetails_Color'] call AFUNC(getControlValue)) param [1, "ColorBlack"];
private _loadoutsStr = [_this, 'Advanced_Loadouts_List'] call AFUNC(getControlValue);

if (_unitSelection isEqualTo []) exitWith {};

private _selectionObjects = allPlayers select {(getPlayerUID _x) in _unitSelection};
_selectionObjects = _selectionObjects arrayIntersect _selectionObjects;

if (_configureGroup && {!isNull _groupLeaderObject}) then {
    private _newGroup = createGroup (side _groupLeaderObject);
    _selectionObjects joinSilent _newGroup;
    _newGroup selectLeader _groupLeaderObject;
    _newGroup setGroupId [_groupName, "GroupColor0"];
    _newGroup setVariable ["ARC_groupColour", _groupColor, true];
    _newGroup setVariable ["ARC_groupHandled", true, true];
    
    private _loadouts = [_loadoutsStr] call CFUNC(listToArray);
    
    if !(_loadouts isEqualTo []) then {
        private _leaderLoadout = _loadouts param [0, "ftl"];
        [_leaderLoadout, _groupLeaderObject] remoteExecCall ["f_fnc_assignGear", _groupLeaderObject];
        
        _loadouts deleteAt 0;
        
        {
            [(selectRandom _loadouts), _x] remoteExecCall ["f_fnc_assignGear", _x];
        } forEach (_selectionObjects select {_x != _groupLeaderObject});
    };
};

switch (toLower _insertionMethod) do {
    case "teleport": {
        {_x setPosATL ([_destination, 10] call CBA_fnc_randPos)} forEach _selectionObjects;
    };
    case "paradrop": {
        [_selectionObjects, _destination, _paraHeight, _paraRadius] remoteExecCall ["ARC_fnc_paraDrop", REMOTE_SERVER];
    };
};