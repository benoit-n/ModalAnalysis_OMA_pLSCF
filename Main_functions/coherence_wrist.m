function coherence_wrist(table_name, fs, n_impact, min_frequency, max_frequency)
%% --- Cohérence indépendante pour capteurs 1,2,3 → 15 ---
pairs = [2 16; 3 16; 4 16];  
nPairs = size(pairs,1);

% --- Décalage pour tenir compte de la colonne temps ---
pairs_idx = pairs;

% --- Paramètres FFT ---
Nseg     = size(table_name,1);
Nfft     = 4*Nseg;
window   = ones(Nseg,1);
noverlap = 0;

figure('Name','Cohérence Capteurs 1-3 → 15','NumberTitle','off');

for p = 1:nPairs
    subplot(nPairs,1,p)
    hold on; grid on

    i_col = pairs_idx(p,1);  % colonne table_name après permutation
    j_col = pairs_idx(p,2);  % colonne table_name après permutation

    Gxy_sum = [];
    Gxx_sum = [];
    Gyy_sum = [];

    for k = 1:n_impact
        x = table_name(:, i_col, k);
        y = table_name(:, j_col, k);

        % --- Calcul CPSD / auto-spectra ---
        Gxy = fftshift(cpsd(x, y, window, noverlap, Nfft, fs, 'twosided'));
        Gxx = fftshift(cpsd(x, x, window, noverlap, Nfft, fs, 'twosided'));
        Gyy = fftshift(cpsd(y, y, window, noverlap, Nfft, fs, 'twosided'));

        f_full = (-Nfft/2:Nfft/2-1).' * fs/Nfft;
        band = (abs(f_full) >= min_frequency) & (abs(f_full) <= max_frequency);
        f = f_full(band);

        if isempty(Gxy_sum)
            Gxy_sum = zeros(length(f),1);
            Gxx_sum = zeros(length(f),1);
            Gyy_sum = zeros(length(f),1);
        end

        Gxy_sum = Gxy_sum + Gxy(band);
        Gxx_sum = Gxx_sum + Gxx(band);
        Gyy_sum = Gyy_sum + Gyy(band);
    end

    den = Gxx_sum .* Gyy_sum;
    den(den < 1e-12) = 1e-12;
    coherence_pair = abs(Gxy_sum).^2 ./ den;

    plot(f, coherence_pair, 'LineWidth',1.5)
    xlabel('Fréquence [Hz]');
    ylabel('Cohérence');
    title(sprintf('Cohérence %d↔%d', pairs(p,1), pairs(p,2)));
    ylim([0 1]);
    xlim([min_frequency max_frequency]);
end

% figure
% plot(table_name(:,1,1),table_name(:,2,1))  % capteur 1
% figure
% plot(table_name(:,1,1),table_name(:,3,1)) % capteur 15
% figure
% plot(table_name(:,1,1),table_name(:,4,1)) % capteur 15
