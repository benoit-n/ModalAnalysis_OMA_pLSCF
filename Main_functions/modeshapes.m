function complexMode = modeshapes(lambda_k, PSD_mean, f, n_output, n_ref)
% =========================================================================
% Compute complex modal vector for a single pole using single-pole residue
% INPUTS:
% - lambda_k  : complex pole
% - PSD_mean  : cross PSD matrix [freq x n_ref x n_output]
% - f         : frequency vector [Hz]
% - n_output  : number of outputs
% - n_ref     : number of references
%
% OUTPUT:
% - complexMode : estimated complex modal vector [n_output x 1]
% =========================================================================

% Frequency of the pole
fn = abs(imag(lambda_k)) / (2*pi);

% Define small frequency band around fn to isolate mode contribution
f_band = 0.1;   % ±10% of fn
mask = (f > fn*(1-f_band)) & (f < fn*(1+f_band));  

PSD_loc = PSD_mean(mask, :, :);
f_loc   = f(mask);
nf = size(PSD_loc,1);

% --- Vectorize PSD over frequency ---
gLambda = zeros(nf * n_output, n_ref);
for i_f = 1:nf
    gLambda((i_f-1)*n_output+1:i_f*n_output, :) = ...
        permute(PSD_loc(i_f, :, :), [3 2 1]);
end

% --- Construct block-diagonal matrix for LS estimation ---
capitalLambda = zeros(nf * n_output, 4 * n_output);
for i_f = 1:nf
    H  = 1 ./ (1i*2*pi*f_loc(i_f) - lambda_k);       % frequency response of pole
    Hc = 1 ./ (1i*2*pi*f_loc(i_f) - conj(lambda_k)); % conjugate

    idx = (i_f-1)*n_output + (1:n_output);

    % Replicate H, Hc on block-diagonal for LS
    capitalLambda(idx, 1:n_output)              = eye(n_output) * H;
    capitalLambda(idx, n_output+1:2*n_output)   = eye(n_output) * Hc;
    capitalLambda(idx, 2*n_output+1:3*n_output) = eye(n_output) * conj(Hc);
    capitalLambda(idx, 3*n_output+1:4*n_output) = eye(n_output) * conj(H);
end

% --- Least-squares estimation of residues ---
ResidueMatrix = capitalLambda \ gLambda;

% --- Extract complex modal vector using first left singular vector ---
[U,~,~] = svd(ResidueMatrix(1:n_output, :), 'econ');
complexMode = U(:, 1);

end

