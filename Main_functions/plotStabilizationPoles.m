function plotStabilizationPoles(polesDict, listBoxHandle, figHandle, ...
                               f_min, f_max, order_max)
% =========================================================================
% plotStabilizationPoles: displays all identified poles on the 
% stabilization diagram with interactive selection.
%
% INPUTS:
%   polesDict      : dictionary containing all poles (key → structure)
%   listBoxHandle  : handle of the listbox UI for interactive selection
%   figHandle      : handle of the main figure for plotting
%   f_min, f_max   : frequency bounds for visualization [Hz]
%   order_max      : maximum model order (used in callbacks)
%
% =========================================================================

% --- Extract all keys from the poles dictionary ---
allKeys = keys(polesDict);  % get a cell array of all keys

% --- Loop through all poles and plot them ---
for i = 1:length(allKeys)
    key = allKeys{i};          % current key
    poleData = polesDict(key); % retrieve pole information structure

    % --- Plot the pole marker ---
    % Very small black circle at (frequency, model order) 
    plot(poleData.f, poleData.ordre, 'ko', 'MarkerSize', 0.01, ...
         'MarkerFaceColor', 'k');

    % --- Plot interactive text label ---
    % Text shows pole status, colored according to pole type
    % Clicking the label triggers onePoleClicked callback
    text(poleData.f, poleData.ordre, poleData.statut, ...
        'FontSize', 10, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'FontWeight','normal', ...
        'Color', poleData.color, ...
        'ButtonDownFcn', @(src,~,~) ...
            onePoleClicked(src, key, polesDict, listBoxHandle, figHandle));
end

end
