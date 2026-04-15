# 📊 Operational Modal Analysis (OMA) – p-LSCF Workflow

![MATLAB](https://img.shields.io/badge/MATLAB-R2025a-blue)
![Toolbox](https://img.shields.io/badge/Required-Signal%20Processing%20Toolbox-orange)
![Status](https://img.shields.io/badge/status-research--project-green)

---

# 📑 Table of Contents

- [📌 Context](#-context)
- [📌 Project Overview](#-project-overview)
- [🏫 Institution](#-institution)
- [📬 Contact](#-contact)

---

# 📌 Context

The **Polyreference Least Squares Complex Frequency-domain (p-LSCF)** method is an Operational Modal Analysis (OMA) technique used to modal parameters.

In OMA, modal parameters are extracted from **output-only measurements**, without requiring knowledge of the input excitation.

Physical modes are identified using a **stabilization diagram**, which compares pole consistency across different model orders.

The method provides:
- Natural frequencies
- Damping ratios
- Complex mode shapes


# 📌 Project Overview

This project implements an **Operational Modal Analysis workflow** based on the p-LSCF method.

The MATLAB script `MAIN_pLSCF.m` includes two main modes:



 🧩 POLES_DETECTION

This mode:
- Identifies system poles across increasing model orders
- Displays an interactive stabilization diagram
- Allows manual selection of physical poles



 🧩 MODAL_SHAPES

This mode:
- Computes complex mode shapes
- Evaluates consistency using the **Modal Assurance Criterion (MAC)**


# 🏫 Institution

Developed as part of a Master’s research project in Mechanical Engineering at **École de technologie supérieure (ÉTS)**, Montréal, Canada.



# 🚀 Getting Started – User Guide

The workflow is fully controlled in the **USER INPUTS** section of `MAIN_pLSCF.m`.

1. Data Preparation

A sample dataset is available in:

To help you get started, a sample dataset is provided in the 'Example_data' folder under 'Records'. 
This dataset is intended only as a working example to launch and test the code.

You can use your own experimental measurements.

Save your measurements in a MAT-file. The data must be organized as a 3D array:
[samples x channels x patches]

- The first column must contain time.
- The remaining columns must contain sensor channels.

Users are free to analyze their own datasets, provided that this structure is respected.

2. Load data file

Open MAIN_pLSCF.m in MATLAB and scroll down to the section labeled USER INPUTS.

All parameters that must be modified by the user are located in the USER INPUTS section.

- Make sure your MAT-file is in the './Records' folder.
- Set the 'file' variable to the name of your MAT-file containing the recorded signals.
Example : file = 'records.mat';

- Assign the loaded table to 'table_name'
Example : records;


3. Select the MODE

For the first analysis, always choose:

MODE = "POLES_DETECTION";

This mode identifies the stable poles using the stabilization diagram.


4. Sampling frequency

Set 'fs' to the sampling frequency of your acquisition system (in Hz).
Example : fs= 6400 Hz;

5. Reference channels

- 'ref' is a vector of column indices in your table that will be used as reference signals.
- Important: these indices do NOT include the time column. Count only the measurement/sensor columns.
- Choose stable sensors located near the excitation points if you can.

Example:
Number of sensors: 15
ref = [1,2,3];


6. Maximum model order

- 'order_max' defines the highest model order the algorithm will test.
- For a first analysis, 10–20 is a good starting point.
- Too low -> some modes may be missed.
- Too high -> the diagram may show spurious poles.


7. Frequency range

'f_min' and 'f_max' define the frequency band to analyze.

Example:
f_min = 0;      % start from 0 Hz
f_max = 1000;   % slightly above expected highest natural frequency 

The sampling frequency 'fs' must be greater than 2 × f_max (Nyquist criterion).

8. Coherence sensors

- 'sensor_1' and 'sensor_2' define the two measurement channels used for coherence calculation (informative purpose only).
- Indices refer only to sensor columns (do NOT count the time column).
- Low coherence may indicate noise, poor excitation, or incorrect sensor selection.


9. Run the script

The program will compute PSD matrices for all impacts and display an interactive stabilization diagram.


10. Stabilization diagram

The stabilization diagram is the core tool to identify physical poles.

- X-axis: frequency in Hz.
- Left Y-axis: model order (order of the polynomial model).
  Each horizontal line corresponds to a model order tested (from 1 up to 'order_max').
- Right Y-axis: mean Power Spectral Density (PSD) in dB/Hz for reference.

Markers:
- Each letter represents a pole (complex root of the identified polynomial model) at a given model order and frequency.

How to read it:
- Poles that appear at the same frequency across several consecutive model orders are considered stable and likely represent physical modes (marked with a green 's'). 
These stable poles generally correspond to peaks visible in the PSD.
- Poles that move significantly between orders are likely spurious and should be ignored.

Interactive selection:
- Click on letters to select the poles you consider physical.
- Selected poles appear in the left panel.
- Use "CLEAR ALL" to reset selections if needed.
- Click "VALIDATE SELECTION" to save the chosen poles.


11. Multi-runs

- The selected poles will be stored in the workspace as 'selected_poles'.
- You can perform multiple runs if necessary to select all desired physical poles.
- After each validation, previously selected poles remain stored, allowing you to progressively build your final selection.


12. Switch to MODAL_SHAPES

Change:

MODE = "MODAL_SHAPES";

in the USER INPUTS section and re-run the script.


13. Modal analysis

- The script computes complex modal vectors (complexModes) for each selected pole.
- The MAC matrix is displayed to check mode consistency.


14. Save results

All computed data (frequencies, damping ratios, and complex mode shapes) are saved automatically in ./Results.


15. Repeat as needed

You can adjust:
- Frequency ranges
- Reference channels

for further analyses.

# 📬 Contact

If you have any questions or suggestions, please feel free to open an issue or contact the author.
