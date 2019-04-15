%% Vicon Integration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 'Integrating Vicon data of body segments and gaze data from Pupil eye 
% tracker for algorithmic gaze detection'
%
%% Requirements:
% 1. BTK-Toolkit: https://code.google.com/archive/p/b-tk/
% 2. .c3d file with segments 'LeftHand', 'RightHand', 'ToriHead', 'UkeHead'
%    'ToriHead', 'CalibrationCross'
% 3. .c3d Vicon file for calibration
% 4. .csv Raw exported Gaze data from Pupil labs
%
%
% This pipeline template assumes the following organization.
%       There is one folder for the analysis containing:
%       - A folder with all data, organized with one folder for each
%         participant that contains all trials of that participant
%           - participant folders labeled 'p01', 'p02', 'p03', etc.
%       - A folder containing all MATLAB functions used in the pipeline 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
close all
clear all  %#ok<CLALL>
clc
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Make inventory of data directory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Go to repository folder
addpath(genpath('C:/Users/Haber/Desktop/Daniel/Gits/ViconPupilintegration'));
 

% Or simply define data folder location:
DataDir = 'C:/Users/Haber/Desktop/Daniel/Gits/ViconPupilIntegration/00_Data';
 
% Load all participant folders
Pfolders_struct = dir(fullfile(DataDir,'P*')); 
% Generate cell array of full-path folder names
Pfolders_cell = fullfile(repmat({DataDir},length(Pfolders_struct),1),{Pfolders_struct.name}');
clear Pfolders_struct
 
%% Cycle through all participants
for p = 1: length(Pfolders_cell) 
    
    % Load all .c3d trial files
    c3dTrials_struct = dir(fullfile(Pfolders_cell{p},sprintf('*.c3d',Pfolders_cell{p}))); %#ok<CTPCT>
    % Use fullfile to generate cell array of full-path file names
    c3dTrialnames_cell = fullfile(repmat({Pfolders_cell{p}},length(c3dTrials_struct),1),{c3dTrials_struct.name}');
    % Save trial names
    trialnamesExtended = {c3dTrials_struct.name}';
    trialnames = regexprep(trialnamesExtended, '.c3d', '');% Remove file extension from trial name
    clear trialnames_struct
    
    % Load all .csv trial files from Pupil eye tracker raw export data
    matTrials_struct = dir(fullfile(Pfolders_cell{p},sprintf('*.csv',Pfolders_cell{p}))); %#ok<CTPCT>
    % Use fullfile to generate cell array of full-path file names
    csvTrialnames_cell = fullfile(repmat({Pfolders_cell{p}},length(matTrials_struct),1),{matTrials_struct.name}');
    clear matTrials_struct
    
    %% Cycle through all trials of each participant
    for t = 1:length(c3dTrialnames_cell)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%  Load and Organize Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% c3d Data Initialization
        % Put a handle on the c3d file (using the btk toolbox)
        h = btkReadAcquisition(c3dTrialnames_cell{t});
        
        %% c3d Positional Data
        % Extract positional data and info from c3d file
        [posData, pointsInfo] = btkGetPoints(h);
        fps_pos = pointsInfo.frequency; % MoCap Sampling Frequency
        
        % ORGANIZE POSITIONAL DATA 
        % Shorten marker names and delete unlabeled markers
        posData = shortenmarkernames(posData);
        % Order fields alphabetically to ensure same marker order for each 
        % trial- may be necessary for filtering later on...
        posData = orderfields(posData);
        marker_names = fieldnames(posData);
        

          
        %% .csv Data
        % Extract data from other file types
        matData = load(csvTrialnames_cell{t}); % Matlab
        %         calubration  = xlsread(trialnames_cell{t}); % Excel
        %         data3 = dlmread(trialnames_cell{t},','); % delimited txt or ASCII file - here delimited by commas
        %         data4 = loadSparkFunIMU(trialnames_cell{t}); % load txt file from SparkFun IMU and organize data into structure
        
        if strncmp(trialnames{t}(6:7), 'calibration') == 1
            Calibration = cal;
            vicon = CAL; 
            continue
        end
        fps_mat = 256; % Sampling frequency of matlab data set
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Preprocess Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        %% Filter Positional Data(Generally) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Low-pass Butterworth Filter for structure of skeleton markers
        posData = filterKinematicsButter(posData,fps_pos,10.4,40);

        
        
        %% .csv Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Depending on you rdata set, you may need to removePeaks, perform
        % a residual analysis to determine filtering parameters, and 
        % low-pass filter or smoothData.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Resample Data
        % Sample down data collected at higher fps to match that of lower fps
        % Here, mat data sampled down to match positional data.
        matData = resampleData(fps_mat, fps_pos, matData)';
        
       
          
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Calculations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Place calculations here...
        
    end % End of trial loop
    
    % Place calculations for participant here (i.e. average over all trials)    
    
end % End of participant loop
 
% Place calculations for all participant here (i.e. average over all participants, export data/graphs) 


