% LICENSE
% =========================================================================
% Licensed under the MIT License.
% See the LICENSE file in the project for more information.
% =========================================================================

%% CODE ORIGIN 
% Inspired by classical Operational Modal Analysis methods:
% Carlo Rainieri & Giovanni Fabbrocino, "Operational Modal Analysis of Civil Engineering Structures:
% An Introduction and Guide for Applications", Springer.

% The author acknowledges Raphael F. Trumpp for his publicly available p-LSCF code,
% (https://github.com/KIT-FAST/modalAnalysis-OMA-EMA), which helped in structuring and implementing this work.

%%
% =========================================================================
%  Project : Experimental Modal Analysis of the Hand–Arm–Nail Gun System Subjected to High-Amplitude Shocks.
%  This project was developed as part of a research project at the École de technologie supérieure (ÉTS), Montréal, Canada.

%  Author  : Naillon Benoit, Master's Student in Mechanical Engineering
%  Date    : April 2026

% Toolbox required : Signal Processing Toolbox
% MATLAB version : R2025a

%% Initialization
clc; clf;
clearvars -except selected_poles;   % Keep selected_poles for multi-run usage
close all;

% Add folders to path
addpath('./Records');
addpath('./Main_functions');
addpath('./Results');

% Start timer
tic;

%% Inputs
% Data organization:
% - table_name should be a 3D array: [samples x channels x impacts/patchs]
%   * samples   : number of time points
%   * channels  : number of sensors (time, sensor1 X, sensor1 Y, sensor1 Z,...)
%   * impacts/patchs  : number of repeated impacts or patchs

% MODE selection :
% "POLES_DETECTION" → The algorithm identifies stable poles across 
%                     increasing model orders and displays them on the 
%                     stabilization diagram, allowing the user to select 
%                     the physical modes.
%
% "MODAL_SHAPES"     → The algorithm computes and extracts the associated 
%                      modal vectors (mode shapes) once the physical poles 
%                      have been identified. 
%                      Switch to "MODAL_SHAPES" after selecting the physical 
%                      modes with POLES_DETECTION.

% ========================================================================
% ========================= USER INPUTS ==================================
% ========================================================================
file       = 'records.mat';       % Records file name
load(file);                             % Load the file into workspace
table_name = records;          % Assign the records table

MODE =  "POLES_DETECTION" ;   % Choose "POLES_DETECTION" or "MODAL_SHAPES"

% Processing Parameters
fs        = 6400;       % Sampling frequency [Hz]
ref     = [1,2,3];      % Vector of reference columns (exclude time)
order_max = 45;         % Maximum model order 

% Frequency Range
f_min =0;         % Minimum frequency [Hz]
f_max =1000;        % Maximum frequency [Hz]
% The sampling frequency 'fs' must be greater than 2 × f_max (Nyquist criterion).

damping_tolerance   = 0.05;     % Relative tolerance on damping ratio.     Default: 0.05
frequency_tolerance = 0.01;     % Relative tolerance on natural frequency. Default: 0.01 

% --- User-selected sensors for coherence calculation (exclude time column)
sensor_1= 3;        % index of first sensor
sensor_2= 15;       % index of second sensor

% ========================= USER INPUTS End ===================================

%% Power Spectral Density (PSD) Computation

% Display the size of the data table: [samples x channels x impacts]
fprintf('\n=== Table size: %d samples x %d channels x %d impacts ===\n', ...
    size(table_name,1), size(table_name,2), size(table_name,3));

% Set frequency band depending on the selected MODE
switch MODE
    case "POLES_DETECTION"
        min_frequency = f_min;
        max_frequency = f_max;

    case "MODAL_SHAPES"
        % Check that selected poles are available
        if ~exist('selected_poles','var') || isempty(selected_poles)
            error('MODAL_SHAPES: No pole selected in memory.');
        end

        min_frequency = 0;   % start from 0 Hz to capture all modes

        % --- WARNING ---
        % This line may cause excessive memory allocation if fs is too high.
        % If an error occurs, reduce the max_frequency here or adjust fs.
        max_frequency = fs/2;     % Adjust according to RAM and Nyquist

    otherwise
        error('Unknown MODE. Choose "POLES_DETECTION" or "MODAL_SHAPES".');
end

% Define the number of output channels and impacts
n_output=size(table_name,2) - 1;    % number of measured responses (excluding time column)
n_impact=size(table_name,3);        % number of repeated impacts
n_ref=length(ref);                  % number of reference channels

% Compute the spectral density matrices:
try
    [f, PSD, PSD_mean, ref_auto_correl, output_auto_correl, Nfft] = ...
                compute_PSDmatrix(table_name, fs, n_ref, n_output, ...
                              min_frequency, max_frequency, n_impact, ref);
catch ME
    % Display informative error message if memory allocation fails
    fprintf(['\n=====================================================\n', 'ERROR during PSD computation\n', 'The frequency band is too large.\n', ...
         'This may cause excessive memory allocation.\n\n', 'Please reduce the frequency band in the user inputs or adjust it at line 109 for the MODAL SHAPES mode.\n', 'Ensure the band still includes all selected modes.\n\n','=====================================================\n\n']);
    return
end
PSD_final = PSD_mean;

%% ===== Modal Shapes Computation =====
switch MODE
    case "MODAL_SHAPES"

    % Number of selected modes
    Nm = numel(selected_poles);

    % Initialize matrix to store complex modal vectors, Dimensions: [n_output x Nm]
    complexModes = zeros(n_output, Nm);

    % --- Construct a table to store pole properties ---
    poleTable = table('Size',[Nm 4], ...
                      'VariableTypes',{'double','double','double','double'}, ...
                      'VariableNames',{'Mode','Frequency_Hz','Damping_percent','Natural_Frequency_Hz'});

    % --- Construct a table to store pole properties ---
    for k = 1:Nm
        lambda_k = selected_poles{k}.pole.poles;    % complex pole

        % Compute the complex modal vector for this pole
        complexModes(:,k) = modeshapes(lambda_k, PSD_final, f, n_output, n_ref);

        % Fill the pole table
        poleTable.Mode(k) = k;
        poleTable.Frequency_Hz(k) = selected_poles{k}.pole.f;
        poleTable.Damping_percent(k) = selected_poles{k}.pole.damping * 100;
        poleTable.Natural_Frequency_Hz(k) = abs(lambda_k)/(2*pi);

    end

    % Display the table of selected poles
    disp('\n=== List of Selected Poles ===\n');
    disp(poleTable);

    % Display the complex modal vectors
    fprintf('\n=== Complex Modal Vectors ===\n');
    disp(complexModes);

    % --- Compute Modal Assurance Criterion (MAC) ---
    % MAC measures the consistency / orthogonality between modes
    MAC = computeMAC(complexModes);

    fprintf('\n=== MAC Matrix ===\n');
    disp(MAC);

    Nm = size(MAC,1);

    % --- Visualize MAC as a heatmap ---
   
    figure('Name','MAC Heatmap','NumberTitle','off');
    imagesc(1:Nm, 1:Nm, MAC);           % Display MAC matrix
    axis square;                        % Square axes for proportionality

    
    nColors = 256;  
    cmap = zeros(nColors,3);  % initialisation [R G B]
    
     % --- Custom colormap: black → red → yellow ---
    for i = 1:nColors
        t = (i-1)/(nColors-1);   % normalisation 0->1
        if t < 0.5
            cmap(i,:) = [2*t, 0, 0];      % black → red
        else
            cmap(i,:) = [1, 2*(t-0.5), 0]; % red → yellow
        end
    end
    
    colormap(cmap);
    colorbar;
    clim([0 1]);  % Set color limits: 0 = low MAC, 1 = high MAC

    xlabel('Mode j'); 
    ylabel('Mode i');
    title('Modal Assurance Criterion (MAC)');

    % --- Save results ---
    [~, name, ~] = fileparts(file);       % Extract filename without extension
    saveFileName = fullfile('./Results',['modalShapes_', name, '.mat']);

    save(saveFileName, 'complexModes', 'poleTable', 'selected_poles','MAC');
    disp(['Modal shapes and poles saved in: ', saveFileName]);

case "POLES_DETECTION"
    %% ===== Coherence =====
    coherence_table = compute_multiImpactCoherence(table_name, fs, sensor_1, sensor_2, ...
        min_frequency,max_frequency);

    %% ===== Poles computation =====
    % Temporarily disable warnings related to nearly singular matrices
    % (commonly encountered during matrix inversion or numerical solving in modal identification)
    w = warning('off','MATLAB:nearlySingularMatrix');

    % Identify system poles from PSD data
    [Dic_total,poles] = identify_poles(order_max,n_ref,n_output,min_frequency,max_frequency,fs,f,PSD_final);
   
    warning(w);     % Restore previous warning state
    
    % t=toc;        % Measure and display poles computation time
    
    %% Stabilization analysis of poles across model orders
    % Classify poles by comparing their frequency and damping evolution between 
    % consecutive model orders (N vs N-1)
    [Dic_sorted] = classify_poles_stability( ...
        Dic_total, order_max, damping_tolerance, frequency_tolerance);
    
    %% Polynomial model validation (LSCF) vs measured PSD
    % Compare the reconstructed polynomial response (LSCF) with the measured PSD
    [SUMauto] = plot_polynomial_model_fit( ...
            poles, fs, max_frequency, min_frequency, order_max, f, PSD_final);
    
    %% ========================================================================
    %  STABILIZATION DIAGRAM (INTERACTIVE)
    %  DESCRIPTION:
    %  Display the stabilization diagram and allow
    %  the user to interactively select physical poles. The selected poles are
    %  stored and reused across sessions.

    % ===== Create figure for stabilization diagram =====
    % Create main figure and initialize axes for stabilization diagram
    figHandle = figure('Name','Stabilization Diagram','NumberTitle','off');
    hold on; 
    grid on;
    
    % --- Configure left axis for model order vs frequency ---
    yyaxis left
    ylabel('Model Order');     % y-axis shows model order
    xlabel('Frequency (Hz)');  % x-axis shows frequency
    
    % --- Initialize selected poles pool ---
    if evalin('base','exist(''selected_poles'',''var'')')
        % Load previously selected poles from workspace if available
        pool = evalin('base','selected_poles');
    else
        pool = {};  % start empty if none exist
    end
    setappdata(figHandle, 'selectedPoles', pool);  % store in figure appdata
    setappdata(figHandle, 'xlineHandles', {});    % initialize vertical lines storage
    
    %% ===== UI panel for selected poles =====
    % Create side panel for selected poles and legend
    listBoxHandle = SelectionPanel(figHandle);
    refreshUI(listBoxHandle, figHandle);  % populate listbox with initial selection
    
    % --- Add 'CLEAR ALL' button to remove all selected poles ---
    uicontrol('Style','pushbutton', 'String','CLEAR ALL', ...
              'Units','normalized', 'Position',[0.02 0.02 0.10 0.05], ...
              'BackgroundColor',[0.9,0.3,0.3], 'FontWeight','bold', ...
              'Callback', @(~,~) clearAllSelectedPoles(figHandle, listBoxHandle));
    
    %% ===== Plot poles on stabilization diagram =====
    % Plots all poles from Dic_sorted with interactive labels
    plotStabilizationPoles(Dic_sorted, listBoxHandle, figHandle);
    
    % ===== Plot PSD on right axis =====
    yyaxis right
    ylabel('PSD (dB/Hz)');  % right y-axis shows PSD
    h = plot(f, 20*log10(abs(SUMauto)), 'LineWidth', 1.2); % plot PSD in dB
    set(h,'PickableParts','none');  % make PSD non-interactive to avoid conflict
    xlim([min_frequency max_frequency]);
    
    % ===== Add 'VALIDATE SELECTION' button =====
    % User clicks to finalize selected poles
    uicontrol('Style','pushbutton', 'String','VALIDATE SELECTION', ...
              'Units','normalized', 'Position',[0.85 0.01 0.12 0.05], ...
              'Callback', @(~,~) uiresume(figHandle));
    
    uiwait(figHandle);  % blocks execution until user clicks 'VALIDATE SELECTION'
    
    % ===== Retrieve final selection from figure appdata =====
    selected_poles = getappdata(figHandle,'selectedPoles');
    
    % --- Sort selected poles by frequency for consistency ---
    if ~isempty(selected_poles)
        [~, idx] = sort(cellfun(@(c) c.pole.f, selected_poles));
        selected_poles = selected_poles(idx);
    end
    
    % --- Save final selection to base workspace ---
    assignin('base','selected_poles', selected_poles);
    
    fprintf('\n=== Stabilization diagram completed. %d poles selected ===\n', numel(selected_poles));
    
    close all;  % closes all open figure windows
end







