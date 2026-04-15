function clearAllSelectedPoles(figHandle, listBoxHandle, f_min, f_max)
    % =========================================================================
    % clearAllSelectedPoles: removes all selected poles from the interface,
    % clears plotted lines, resets the listbox, and updates the figure appdata.
    %
    % INPUTS:
    %   figHandle      : handle of the main figure
    %   listBoxHandle  : handle of the listbox displaying selected poles
    %   f_min, f_max   : frequency bounds (kept for consistency)
    %
    % NOTE:
    %   This function:
    %     - clears the selection pool
    %     - removes all plotted xlines
    %     - resets the UI via refreshUI
    %     - updates the appdata in the figure
    %
    % =========================================================================
    
    % --- Confirmation dialog before clearing all selections ---
    choice = uiconfirm(figHandle, ...
        'Delete all selected poles ?', ...
        'Confirmation', ...
        'Options', {'Yes','No'}, ...
        'DefaultOption', 2, ...
        'CancelOption', 2);
    
    % --- Exit if user cancels ---
    if ~strcmp(choice,'Yes')  % user chose 'No' or cancelled
        return
    end
    
    % --- Clear selected poles pool ---
    selectedPoles = {};                      % reset selection
    setappdata(figHandle, 'selectedPoles', selectedPoles);
    
    % --- Clear all vertical lines (xlines) from figure ---
    if isappdata(figHandle, 'xlineHandles')
        xlineHandles = getappdata(figHandle, 'xlineHandles');  % retrieve handles
        for k = 1:numel(xlineHandles)
            if isgraphics(xlineHandles{k}.handle)               % check if handle is valid
                delete(xlineHandles{k}.handle);                % delete line from figure
            end
        end
        % Reset appdata to empty
        setappdata(figHandle, 'xlineHandles', {});
    end
    
    % --- Update UI to reflect cleared selection ---
    % frequency bounds passed as 0,0 just to refresh listbox
    refreshUI(listBoxHandle, figHandle, 0, 0);
    
    end