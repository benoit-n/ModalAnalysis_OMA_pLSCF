function coherence_vector = compute_multiImpactCoherence(table_name, fs, sensor_1, sensor_2, min_frequency,max_frequency)

% Compute multi-impact coherence between two sensors
%
% INPUTS:
% - table_name    : 3D array [samples x channels x impacts], raw signals
% - fs            : sampling frequency [Hz]
% - sensor_1      : index of first sensor (MATLAB indexing)
% - sensor_2      : index of second sensor
% - min_frequency : minimum frequency to display in plot [Hz]
% - max_frequency : maximum frequency to display in plot [Hz]
%
% OUTPUTS:
% - coherence_vector : coherence values as a vector [frequency x 1]
% =========================================================================

% --- Adjust sensor indices if first column is time
sensor1_idx=sensor_1+1;
sensor2_idx=sensor_2+1;

% --- Determine number of impacts and samples ---
n_impact = size(table_name,3);
Nseg     = size(table_name,1);      % Number of samples
Nfft     = 4*Nseg;                  % FFT length 
window   = ones(Nseg,1);            % rectangular window
noverlap = 0;
nf = Nfft/2 + 1;

% --- Initialize matrices to store PSDs for all impacts ---
PSD_cross = zeros(nf, n_impact);    % cross PSD between sensor1 and sensor2
PSD_1     = zeros(nf, n_impact);    % auto PSD sensor1
PSD_2     = zeros(nf, n_impact);    % auto PSD sensor2

% --- Loop over all impacts and compute PSDs ---
for k = 1:n_impact
    x = table_name(:, sensor1_idx, k);  % signal from sensor 1
    y = table_name(:, sensor2_idx, k);  % signal from sensor 2
    
    % Cross PSD: X-Y
    [Pxy,f] = cpsd(x, y, window, noverlap, Nfft, fs);
    PSD_cross(:,k) = Pxy;
    
    % Auto PSDs
    [Pxx,~] = cpsd(x, x, window, noverlap, Nfft, fs);
    [Pyy,~] = cpsd(y, y, window, noverlap, Nfft, fs);
    
    PSD_1(:,k) = Pxx;
    PSD_2(:,k) = Pyy;
end

% --- Average PSDs over all impacts ---
Gxy = mean(PSD_cross,2);
Gxx = mean(PSD_1,2);
Gyy = mean(PSD_2,2);

% --- Compute coherence ---
eps_val = 1e-12;                        % avoid division by zero
den = Gxx .* Gyy;
den(den < eps_val) = eps_val;
coherence_vector = abs(Gxy).^2 ./ den;   % coherence at each frequency

% --- Plot ---
figure('Name','Coherence','NumberTitle','off');
plot(f, coherence_vector, 'LineWidth',1.8, 'Color',[0 0.45 0.74]);
grid on;
xlabel('Frequency [Hz]');
ylabel('Coherence');
title(sprintf('Coherence — SENSOR %d → SENSOR %d', sensor_1, sensor_2));
ylim([0 1.1]);
xlim([min_frequency max_frequency]);
end


