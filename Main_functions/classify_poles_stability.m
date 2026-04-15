function [Dic_sorted] = classify_poles_stability( ...
    Dic_total, order_max, damping_tolerance, frequency_tolerance)

% ========================================================================
%  POLE STABILIZATION CLASSIFICATION
%
%  A pole is considered:
%   - unstable in frequency → if relative frequency variation is too large
%   - unstable in damping   → if relative damping variation is too large
%  This step is used to build a stabilization diagram.
%
%  INPUTS:
%  - Dic_total           : dictionary containing poles for all model orders
%                         keys format: 'order;index'
%  - order_max           : maximum model order
%  - damping_tolerance   : relative tolerance on damping variation
%  - frequency_tolerance : relative tolerance on frequency variation
%
%  OUTPUT:
%  - Dic_sorted          : updated dictionary with stability classification
%                         fields added:
%                           .statut → 'f' (freq), 'd' (damping), or stable
%                           .color  → visualization color
%
%  ========================================================================

% Initialize output dictionary
Dic_sorted = Dic_total;

% Retrieve all keys
keys_all = keys(Dic_sorted);

% Loop over model orders
for order = 1:order_max
    
    % Keys for current and previous orders
    keys_current = keys_all(startsWith(keys_all, sprintf('%d;', order)));
    keys_prev    = keys_all(startsWith(keys_all, sprintf('%d;', order-1)));
    
    % Skip if missing data
    if isempty(keys_current) || isempty(keys_prev)
        continue;
    end

    % Extract pole structures
    poles_current = Dic_sorted(keys_current);
    poles_prev    = Dic_sorted(keys_prev);

    % Compare poles
    for k = 1:length(poles_current)
        
        f_now = poles_current(k).f;
        d_now = poles_current(k).damping;

        % Find closest pole in frequency (previous order)
        freq_diff = abs([poles_prev.f] - f_now);
        [~, idx] = min(freq_diff);

        f_prev = poles_prev(idx).f;
        d_prev = poles_prev(idx).damping;

        % Retrieve full data structure
        data = Dic_sorted(keys_current{k});

        % --- Stability checks ---

        % Frequency stability
        if abs((f_now - f_prev) / f_prev) > frequency_tolerance
            data.statut = 'f';   % unstable in frequency
            data.color  = 'r';

        % Damping stability
        elseif abs((d_now - d_prev) / d_prev) > damping_tolerance
            data.statut = 'd';   % unstable in damping
            data.color  = 'b';
        end

        % Update dictionary
        Dic_sorted(keys_current{k}) = data;
    end
end