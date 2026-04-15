function [f, PSD, PSD_mean, ref_auto_correl, output_auto_correl, Nfft] = ...
    compute_PSDmatrix(table_name, fs, n_ref, n_output, ...
                              min_frequency, max_frequency, n_impact, ref)
% ========================================================================
% Compute cross and auto Power Spectral Densities (PSD)
%
% INPUTS:
% - table_name   : 3D array [samples x channels x impacts]
% - fs           : sampling frequency [Hz]
% - n_ref        : number of reference channels
% - n_output     : number of output channels
% - min_frequency: minimum frequency of interest [Hz]
% - max_frequency: maximum frequency of interest [Hz]
% - n_impact     : number of repeated impacts/trials
% - ref          : indices of reference channels
%
% OUTPUTS:
% - f                : frequency vector within [min_frequency, max_frequency]
% - PSD              : cross PSD matrix [freq x n_ref x n_output x n_impact]
% - PSD_mean         : mean cross PSD over impacts
% - ref_auto_correl   : reference auto-PSD matrix [freq x n_ref x n_ref x n_impact]
% - output_auto_correl: output auto-PSD matrix [freq x n_output x n_output x n_impact]
% - Nfft             : FFT length 
% ========================================================================

%% --- Dimensions and FFT setup ---
Nseg     = size(table_name,1);      % Number of samples
Nfft     = 4*Nseg;                  % FFT length 
window   = ones(Nseg,1);            % rectangular window
noverlap = 0;                       % no overlap


% Adjust indices: column 1 = time
time_col = 1;  
ref = ref + 1;      % shift reference indices

% Reorder table: [time, references, other channels]
other_cols = setdiff(2:size(table_name,2), ref);
table_name = table_name(:, [time_col, ref, other_cols], :);

% --- Separate reference and output signals ---
recordsRef = table_name(:, 2:n_ref+1, :);
recordsMov = table_name(:, 2:end, :);

% --- Frequency vector (two-sided) ---
f_full = (-Nfft/2:Nfft/2-1).' * fs/Nfft;

% Select frequency band of interest
band = (abs(f_full) >= min_frequency) & ...
       (abs(f_full) <= max_frequency);

f = f_full(band);
nf = length(f);

% --- Initialize output matrices ---
PSD = zeros(nf, n_ref, n_output, n_impact);
ref_auto_correl = zeros(nf, n_ref, n_ref, n_impact);
output_auto_correl = zeros(nf, n_output, n_output, n_impact);

% ===== Compute cross PSD (two-sided) =====
for i_out = 1:n_output
    for j_ref = 1:n_ref
        for k = 1:n_impact % impacts or samples
            % Compute cross-PSD between reference j_ref and output i_out
            PSDtmp = cpsd(recordsRef(:,j_ref,k), ...
                        recordsMov(:,i_out,k), ...
                        window, noverlap, Nfft, fs, 'twosided');

            PSDtmp = fftshift(PSDtmp);   % Compute cross-PSD between reference j_ref and output i_out
            PSD(:,j_ref,i_out,k) = PSDtmp(band);  % keep only selected frequency band
        end
    end
end

% Mean cross PSD over all impacts
PSD_mean = mean(PSD,4);
