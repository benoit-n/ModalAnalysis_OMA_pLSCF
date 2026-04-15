function removeSelectedPole(listBoxHandle, figHandle)
% =========================================================================
% removeSelectedPole: removes the currently selected pole from the selection
% pool and the figure, updates the listbox UI, and syncs the workspace.
%
% INPUTS:
%   listBoxHandle  : handle of the listbox displaying selected poles
%   figHandle      : handle of the main figure
%
% =========================================================================

% --- Get index of currently selected item in the listbox ---
idx = get(listBoxHandle, 'Value');

% --- Retrieve stored selected poles from figure appdata ---
selectedPoles = getappdata(figHandle, 'selectedPoles');

% --- Check if selection is valid ---
% Exit if no selection or index is out of bounds
if isempty(selectedPoles) || isempty(idx) || idx < 1 || idx > numel(selectedPoles)
    return;
end

% --- Identify the pole to remove ---
keyToRemove = selectedPoles{idx}.key;

% --- Remove pole from selection pool ---
selectedPoles(idx) = [];

% --- Remove corresponding vertical line (xline) from figure ---
xlineHandles  = getappdata(figHandle, 'xlineHandles'); % retrieve current xlines
newXlines = {};  % initialize new list of xline handles

for k = 1:numel(xlineHandles)
    if strcmp(xlineHandles{k}.key, keyToRemove)
        % Delete graphics object if still valid
        if isgraphics(xlineHandles{k}.handle)
            delete(xlineHandles{k}.handle);
        end
    else
        % Keep other xlines
        newXlines{end+1} = xlineHandles{k};
    end
end

% --- Update figure appdata with new selected poles and xlines ---
setappdata(figHandle, 'selectedPoles', selectedPoles);
setappdata(figHandle, 'xlineHandles', newXlines);

% --- Update UI (listbox) ---
if ~isempty(selectedPoles)
    % Refresh listbox to show remaining selected poles
    refreshUI(listBoxHandle, figHandle, selectedPoles);
else
    % Clear listbox if no poles left
    set(listBoxHandle, 'String', {});
end

% --- Sync selection pool to base workspace for external access ---
assignin('base','selected_poles', selectedPoles);

end
