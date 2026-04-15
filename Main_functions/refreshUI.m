function refreshUI(listBoxHandle, figHandle, f_min_global, f_max_global)
% =========================================================================
% refreshUI: updates the listbox and the stabilization diagram
% to reflect the currently selected poles.
%
% INPUTS:
%   listBoxHandle  : handle of the listbox UI
%   figHandle      : handle of the main figure
%   f_min_global   : global minimum frequency for plotting (Hz)
%   f_max_global   : global maximum frequency for plotting (Hz)
%
% =========================================================================

% --- Retrieve currently selected poles from figure appdata ---
selectedPoles = getappdata(figHandle, 'selectedPoles');

% --- Update listbox with selected poles ---
if isempty(selectedPoles)
    % If no poles are selected, clear the listbox
    set(listBoxHandle, 'String', {}, 'Value', 1);
else
    % Build cell array of strings describing each selected pole
    listStrings = cell(1, numel(selectedPoles));
    for k = 1:numel(selectedPoles)
        pd = selectedPoles{k}.pole; % retrieve pole structure
        % Format: "Mode <key> : <frequency> Hz <damping>%"
        listStrings{k} = sprintf('Mode %s  :  %.2f Hz  %.1f%%', ...
            selectedPoles{k}.key, pd.f, pd.damping*100);
    end
    % Update listbox content and reset selection to first entry
    set(listBoxHandle, 'String', listStrings, 'Value', 1);
end

% --- Refresh vertical lines (xlines) on the figure ---
xlineHandles = getappdata(figHandle,'xlineHandles'); % previously plotted lines
if isempty(xlineHandles)
    xlineHandles = {}; % initialize if empty
end

% Loop over all selected poles
for k = 1:numel(selectedPoles)
    key = selectedPoles{k}.key;

    % Check if a vertical line for this pole already exists
    exists = any(cellfun(@(x) strcmp(x.key,key), xlineHandles));
    if ~exists
        % Plot a new vertical line at the pole frequency
        h = xline(selectedPoles{k}.pole.f, '--b', 'LineWidth', 2);
        % Store the handle and key in xlineHandles
        xlineHandles{end+1} = struct('key', key, 'handle', h);
    end
end

% --- Save updated xline handles back to figure appdata ---
setappdata(figHandle,'xlineHandles',xlineHandles);

end