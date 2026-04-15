function [SUMauto] = plot_polynomial_model_fit( ...
    poles, fs, max_frequency, min_frequency, order_max, f, PSD_final)
% ========================================================================
%  POLYNOMIAL MODEL VALIDATION (PSD COMPARISON)
%  This allows visual validation of the model quality and convergence.
%
%  INPUTS:
%  - poles         : cell array containing identified poles for each order
%  - fs            : sampling frequency [Hz]
%  - max_frequency : upper frequency bound [Hz]
%  - min_frequency : lower frequency bound [Hz]
%  - order_max     : maximum model order
%  - f             : frequency vector [Hz]
%  - PSD_final     : averaged PSD matrix [freq x n_ref x n_output]
%
%  OUTPUT:
%  - SUMauto       : averaged auto-PSD over reference channels
%  ========================================================================

%% --- Compute averaged auto-PSD over references ---
nf = length(f);
SUMauto = zeros(nf,1);

n_ref = size(PSD_final,2);  
for i = 1:n_ref
    SUMauto = SUMauto + PSD_final(:,i,i);
end

SUMauto = SUMauto / n_ref;

% -------------------------------------------------------------------------
% Figure (docked)
% -------------------------------------------------------------------------
fig = figure('WindowStyle','docked', ...
             'Name','Polynomial Model vs Auto-PSD Reference', ...
             'NumberTitle','off');

% -------------------------------------------------------------------------
% Frequency grid for polynomial reconstruction
% -------------------------------------------------------------------------
f_eval = linspace(min_frequency, max_frequency, 1000);
s = exp(1i*2*pi*f_eval*(1/fs));

% Normalization factor
PSD_max = max(abs(SUMauto));

%% ========================================================================
% SUBPLOT 1 — Maximum model order
% ========================================================================
subplot(1,2,1,'Parent',fig);
hold on;

ordre_struct_max = poles{end};
lambda_max = ordre_struct_max.lambda;

z_max = exp(lambda_max*(1/fs));
p_max = poly(z_max);

% Frequency response reconstruction
H = 1 ./ polyval(p_max, s);
H_norm = abs(H) * PSD_max / max(abs(H));

% Plot measured PSD
plot(f, 10*log10(abs(SUMauto)), 'b', ...
     'LineWidth', 2, 'DisplayName','Auto PSD');

% Plot polynomial model
plot(f_eval, 10*log10(H_norm), 'r', ...
     'LineWidth', 2, ...
     'DisplayName', sprintf('Order %d', order_max));

xlim([min_frequency max_frequency])
ylabel('Amplitude (dB)')
title('Maximum Order vs PSD')
grid on
legend show

%% ========================================================================
% SUBPLOT 2 — Lower model orders comparison
% ========================================================================
subplot(1,2,2,'Parent',fig);
hold on;

plot(f, 10*log10(abs(SUMauto)), 'b', ...
     'LineWidth', 2, 'DisplayName','Auto PSD');

n_plot = min(3, numel(poles));

for k = 1:n_plot
    ordre_struct = poles{k};
    lambda = ordre_struct.lambda;

    z = exp(lambda*(1/fs));
    p = poly(z);

    H = 1 ./ polyval(p, s);
    H_norm = abs(H) * PSD_max / max(abs(H));

    plot(f_eval, 10*log10(H_norm), ...
         'LineWidth', 1.3, ...
         'DisplayName', sprintf('Order %d', ordre_struct.ordre));
end

xlim([min_frequency max_frequency])
xlabel('Frequency (Hz)')
ylabel('Amplitude (dB)')
title('Lower Orders Comparison')
grid on
legend show
