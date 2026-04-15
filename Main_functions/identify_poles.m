function [Dic_total,poles] = identify_poles(order_max,n_ref,n_output,min_frequency,max_frequency,fs,f,PSD_final)
% ========================================================================
%  POLE IDENTIFICATION FROM PSD MATRIX

%  INPUTS:
%  - order_max      : maximum model order used for identification
%  - n_ref          : number of reference channels
%  - n_output       : number of output channels
%  - min_frequency  : minimum frequency of interest [Hz]
%  - max_frequency  : maximum frequency of interest [Hz]
%  - fs             : sampling frequency [Hz]
%  - f              : frequency vector [Hz]
%  - PSD_final      : cross-PSD matrix 
%                     [nf x n_ref x n_output]
%
%  OUTPUTS:
%  - stabilization_data : structure containing results across model orders
%                         (used for stabilization diagram)
%  - poles              : identified poles (frequency, damping, etc.)
%
%  ========================================================================

%% Initialize
poles = {};            % Initialize cell array to store poles for selected orders
n_f   = length(f);     % Number of frequency points from PSD
T_s   = 1/fs;          % Sampling period [s]

%% Compute Gamma and Ypsilon_max matrix for all frequencies

% Gamma_max [n_f, order_max+1]
Gamma_max = exp(1i * 2 * pi * f(1:end) * T_s .* (0:(order_max))); 

% Initialize Ypsilon matrix
Ypsilon_max = zeros(n_f, (order_max+1) * n_ref, n_output);

% Fill Ypsilon_max with Kronecker product of Gamma and GYY
for i_out = 1:n_output
    for i_f = 1:n_f
        Ypsilon_max(i_f, :, i_out) = -kron(Gamma_max(i_f, :), PSD_final(i_f, :, i_out) );
    end
end

% Dictionary to store stable poles
Dic_total = dictionary(string([]), struct([]));

%% Loop over model orders
for n_order=1:order_max
    % Slice Gamma and Ypsilon matrices for the current model order (n_order)
    Gamma = Gamma_max(:,1:n_order+1);   
    Ypsilon = Ypsilon_max(:, 1 : (n_order + 1) * n_ref, :); 

    % Initialize S and T matrices
    S = zeros(n_order+1, (n_order+1)*n_ref, n_output);
    T = zeros((n_order+1)*n_ref, (n_order+1)*n_ref, n_output);

    % Compute S and T for each output
    for i = 1:n_output        
        S(:,:,i) = Gamma' * Ypsilon(:,:,i);   
        T(:,:,i) = Ypsilon(:,:,i)' * Ypsilon(:,:,i);      
    end

    R = real(Gamma'*Gamma);
    S = real(S);
    T = real(T);

    % M matrix
    M = zeros((n_order+1)*n_ref);        % Initialize M
    for i = 1:n_output
        M(:,:,i)= (T(:,:,i) ...
            -S(:,:,i)'/ R * S(:,:,i));   % ((n_order+1)*n_ref)²
    end
    M=sum(M,3);                          % Sum over outputs

    % Partition M
    % M22: (n_order * n_ref) × (n_order * n_ref)
    % M21: (n_order * n_ref) × n_ref
    M22 = M(n_ref+1:(n_order + 1) * n_ref, n_ref+1:(n_order + 1) *n_ref);
    M21 = M(n_ref+1:(n_order+1)*n_ref, 1 :n_ref);
    
    alpha_m = - (M22 \ M21);
    alpha = [eye(n_ref); alpha_m];

    %% Construct companion matrices and compute eigenvalues

    % Initialize An
    An=zeros(n_ref,n_ref);

    % Fill An with blocks of alpha
    for i_order = 0 : n_order
        An(:, :, i_order+1)= ...
            alpha(i_order * n_ref + 1 : (i_order + 1) * n_ref, 1 : n_ref);
    end  

    % Initialize C
    C = zeros(n_order*n_ref);

    % Build companion matrix C
    for i_order = 1 : n_order 
        C(1:n_ref, (i_order-1)*n_ref+1 : i_order*n_ref)=-An(:,:,n_order+1)\An(:,:,n_order+1-i_order);
    end
    
    % Fill the lower part with identity matrices
    C(1+n_ref : n_ref*n_order, 1 : n_ref * n_order - n_ref) = eye(n_order * n_ref - n_ref);
    
    % Compute eigenvalues of companion matrix
    z = eig(C);                                 % z = eigenvalues of C
    lambda = log(z)/T_s;                        % Continuous-time poles

    % Define orders to store for plotting purposes
    % Take 100%, 85%, 70%, and 55% of the maximum model order
    orders_to_plot = round(order_max * [1 0.85 0.70 0.55], 0);

    if ismember(n_order, orders_to_plot)
        poles{end+1} = struct('ordre', n_order, 'lambda', lambda);
    end

    % Store poles in dictionary with relevant properties
    Dic_temp = dictionary(string([]), struct([]));
    a=1;

    % Keep only stable poles :
    %  - Frequency of the pole is within [min_frequency, max_frequency]
    %  - Real part is negative (stable)
    %  - Imaginary part positive (only upper half-plane to avoid duplicates)
    for idx = 1:length(lambda)
        i = lambda(idx);
        if (imag(i) / (2*pi)>=min_frequency) && (imag(i) / (2*pi)<=max_frequency) && ...
            real(i) < 0 && imag(i) > 0
            % Generate a unique key for the dictionary based on order and index
            key=sprintf('%d;%d', n_order, a);   
            data=struct('ordre',n_order,'f',imag(i) / (2*pi),'damping', ...
                -real(i) ./ abs(i),'poles',i,'statut',char("s"),'color',char("g"));
            % Add the pole info to temporary dictionary
            Dic_temp(key)=data;                      
            a=a+1;
        end
    end

    % Merge temporary dictionary into global dictionary
    all_keys = keys(Dic_temp);
    for j = 1:length(keys(Dic_temp))
        key = all_keys {j};            
        Dic_total(key) = Dic_temp(key);
    end
end



