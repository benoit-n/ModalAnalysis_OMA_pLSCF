function onePoleClicked(~, poleKey, polesDict, listBoxHandle, figHandle, f_min, f_max, order_max)
% =========================================================================
% onePoleClicked: callback function triggered when a pole label is clicked.
% Adds the selected pole to the list of selected poles, plots a vertical line,
% and updates the UI.
%
% INPUTS:
%   ~              : unused source object from callback
%   poleKey        : key of the clicked pole in polesDict
%   polesDict      : dictionary containing all poles
%   listBoxHandle  : handle of the listbox UI
%   figHandle      : handle of the main figure
%   f_min, f_max   : frequency bounds for plotting (not used directly here)
%   order_max      : maximum model order (not used directly here)
%
% =========================================================================

% --- Retrieve previously selected poles and plotted lines from figure appdata ---
selectedPool = getappdata(figHandle, 'selectedPoles'); % previously selected poles
xlineHandles = getappdata(figHandle, 'xlineHandles');  % previously plotted vertical lines

% --- Initialize if empty ---
if isempty(selectedPool), selectedPool = {}; end
if isempty(xlineHandles), xlineHandles = {}; end

% --- Retrieve data for the clicked pole ---
poleData = polesDict(poleKey); % get pole structure for the clicked key

% --- Check if pole is already selected ---
% If the pole is already in selectedPool, exit the function
if any(cellfun(@(c) strcmp(c.key, poleKey), selectedPool))
    return
end

% --- Add new pole to selectedPool ---
newEntry = struct('key', poleKey, 'pole', poleData); % create a new structure
selectedPool{end+1} = newEntry;                       % append to cell array

% --- Plot vertical line at pole frequency ---
hLine = xline(poleData.f, 'b--', 'LineWidth', 2);     % blue dashed line
xlineHandles{end+1} = struct('handle', hLine, 'key', poleKey); % store handle and key

% --- Update figure appdata with new selections ---
setappdata(figHandle, 'selectedPoles', selectedPool);
setappdata(figHandle, 'xlineHandles', xlineHandles);

% --- Update listbox and refresh UI ---
freqs = cellfun(@(c)c.pole.f, selectedPool);         % extract frequencies of selected poles
refreshUI(listBoxHandle, figHandle, min(freqs), max(freqs)); % update UI display

end
