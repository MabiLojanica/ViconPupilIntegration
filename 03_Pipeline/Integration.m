%% Pipeline_Template
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 'Description of Pipeline'
%
% This pipeline template assumes the following organization.
%       There is one folder for the analysis containing:
%       - A folder with all data, organized with one folder for each
%         participant that contains all trials of that participant
%           - participant folders labeled 'v01', 'v02', 'v03', etc.
%       - A folder containing all MATLAB functions used in the pipeline
% The general template below requires you to delete unnecessary portions 
% and adapt file types as needed for your project. 
%
% Written by: 'Author'
%
% Created: 'Date'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
close all
clear all  %#ok<CLALL>
clc
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Make inventory of data directory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% % Let user point to the directory, containing data and all functions used:
% MainDir = uigetdir([],'Select directory folder:');
% % And add to path:
% addpath(genpath(MainDir));
 
% Or simply go straight to folder:
addpath(genpath('D:\Matlab_Project'));
 
% % Let user point to the DATA directory, the folder in the directory with 
% % all data folders:
% DataDir = uigetdir([],'Select data folder:');
 
% Or simply define data folder location:
DataDir = 'D:\Matlab_Project\Data_Test';
 
% Load all participant folders
Pfolders_struct = dir(fullfile(DataDir,'v*')); 
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
    trialnames = {c3dTrials_struct.name}';
    trialnames = regexprep(trialnames, '.c3d', '');% Remove file extension from trial name
    clear trialnames_struct
    
    % Load all .mat (ie. EOG) trial files ( or '*.xls', '*.txt', etc. for other file types)
    matTrials_struct = dir(fullfile(Pfolders_cell{p},sprintf('*.mat',Pfolders_cell{p}))); %#ok<CTPCT>
    % Use fullfile to generate cell array of full-path file names
    matTrialnames_cell = fullfile(repmat({Pfolders_cell{p}},length(matTrials_struct),1),{matTrials_struct.name}');
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
        
        %% c3d Force Data
         % Extract force data and info from c3d file
        forceData = btkGetGroundReactionWrenches(h);
        forcePlates = btkGetForcePlatforms(h);
        [~, analogsInfo] = btkGetAnalogs(h);
        
        corners1 = forcePlates(1).corners;% Coordinates of FP1 corners
        corners2 = forcePlates(2).corners;% Coordinates of FP1 corners
        fps_FP = analogsInfo.frequency;% Force Plate Sampling Frequency
        clear h  % clear when you no longer need the handle...
          
        %% .mat Data
        % Extract data from other file types
        matData = load(matTrialnames_cell{t}); % Matlab
        %         calubration  = xlsread(trialnames_cell{t}); % Excel
        %         data3 = dlmread(trialnames_cell{t},','); % delimited txt or ASCII file - here delimited by commas
        %         data4 = loadSparkFunIMU(trialnames_cell{t}); % load txt file from SparkFun IMU and organize data into structure
        
        if strncmp(trialnames{t}(6:7), 'cl') == 1
            Calibration = cal;
            vicon = CAL; 
            continue
        end
        fps_mat = 256; % Sampling frequency of matlab data set
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Preprocess Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Remove Peaks 
        % Remove unrealistic jumps in data
        % Select the function that corresponds to your data type:
        % n x m data double
        data_gap = removePeaks(posData.RTOE, 0, 1, trialnames{t}, 1, '.jpg');
        % Skeleton - structure of markers
        gapKinData = removePeaksMarkers(posData, 0, 1, trialnames{t}, 1, '.jpg');
                
        %% Residual Analysis (for Low-pass Filtering)
        % Perform a residual analysis to determine the optimal low-pass filter
        % parameters for your dataset. This only needs to be performed once
        % at the beginning of analysis to obtain relevant parameters.
        
        % Three options below:
        
        % Residual analysis for a simple 3rd order Low-pass Butterworth Filter. 
        % Determines optimal cutoff frequency. 
        [residual, f_ideal] = residualAnalysis(data, fps_pos, 1, trialName{t}, 0, '.jpg');
        
        % Residual analysis for developed Low-pass Butterworth Filter (filtButter). 
        % Provides residuals to determine optimal cut off and stopband frequencies. 
        residual_table = residualAnalysis_BUTTER(data, fps_pos);
 
        % Residual analysis for a simple Low-pass Butterworth Filter. Provides
        % optimal cut off frequencies(and their residuals) for filters of orders 1-9.
        resid_result = residualAnalysis_ORDER(data, fps_pos, 1, trialName{t}, 0, '.jpg');
        
        %% FILTER DATA
        %% 1. Filter Positional Data (Nearest Neighbor Approximation for Skeletons)
        % Put data from ALL markers in a single matrix. Each row contains a
        % single sample (i.e. a single point in time) from all markers.
        % Columns are organized as follows: 
        % [x_marker1 y_marker1 z_marker1 x_marker 2 y_marker2 z_marker2 ... x_markerN y_markerN z_markerN].
        Data_Gaps = cell2mat(struct2cell(posData)');
        Data_Raw = Data_Gaps;
        Data_Final = preprocess_plug_in_gait(Data_Raw,{fps_pos,10,3,10,6,.5,.02,.99,marker_names},0);
        
        % Place final data back in posData structure
        for i_marker =  1:length(marker_names)
            posData.(char(marker_names(i_marker))) = Data_Final(:,3*i_marker-2:3*i_marker);
        end
        
        %% OR
        
        %% 2. Filter Positional Data(Generally)
        % Low-pass Butterworth Filter for structure of skeleton markers
        posData = filterKinematicsButter(posData,fps_pos,10.4,40);
        
        % Low-pass Butterworth Filter for data in a matrix
        filtData = filterButter(data, fps_pos,10.4,40);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Smooth 3D Force Data
        F1 = smoothData(forceData(1).F, (fps_FP* 1/50)); % Force plate 1
        F2 = smoothData(forceData(2).F, (fps_FP* 1/50)); % Force plate 2
        
        %% Filter COP
        % It may be necessary to remoovePeaks in the COP data, and perform a 
        % residual analysis for optimal filtering parameters.
        % Low-pass Butterworth Filter for data in a matrix
        COP1 = filterButter(forceData(1).P,fps_FP,2.5,8);
        COP2 = filterButter(forceData(2).P,fps_FP,2.5,8);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% .mat Data
        % Depending on you rdata set, you may need to removePeaks, perform
        % a residual analysis to determine filtering parameters, and low-pass 
        % filter or smoothData.
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Resample Data
        % Sample down data collected at higher fps to match that of lower fps
        % Here, mat data sampled down to match positional data.
        matData = resampleData(fps_mat, fps_pos, matData)';
        
        %% Combine force plates
        [Fnet, Mnet, COPnet, Tfree] = addForcePlates(F1, F2, COP1, COP2, corners1, corners2);
          
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Calculations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Place calculations here...
        
    end % End of trial loop
    
    % Place calculations for participant here (i.e. average over all trials)    
    
end % End of participant loop
 
% Place calculations for all participant here (i.e. average over all participants, export data/graphs) 


