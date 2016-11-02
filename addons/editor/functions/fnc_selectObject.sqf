/*
 * Author: Kingsley
 * Handles selecting an object via left click
 *
 * Arguments:
 * 0: Objects to select (optional) <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call mars_editor_fnc_selectObject;
 *
 * Public: No
 */

#include "script_component.hpp"

params [["_objects", [], [[]]]];

if (_objects isEqualTo []) then {
    private _target = [] call FUNC(objectUnderCursor);

    if (_target == GVAR(prepSurfaceSphere)) exitWith {};

    if (isNull _target) then {
        private _selectedGroup = [] call FUNC(selectGroupIcon);

        if (isNull _selectedGroup) then {
            GVAR(selection) = [];
        } else {
            {
                [_x, !(vehicle _x == _x), false] call FUNC(highlightObject);
                false
            } count units _selectedGroup;
        };
    } else {
        [_target, !(vehicle _target == _target)] call FUNC(highlightObject);
    };
} else {
    if (!GVAR(ctrlKey)) then {
        GVAR(selection) = [];
    };

    {[_x, !(vehicle _x == _x), false] call FUNC(highlightObject);false} count _objects;
};
