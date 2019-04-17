%% Vicon Integration Head Orientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 'Integrating Vicon data of body segments and gaze data from Pupil eye 
% tracker for algorithmic gaze detection'
%
% Requirements:
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
% Make inventory of data directory
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
    csvTrials_struct = dir(fullfile(Pfolders_cell{p},sprintf('*.csv',Pfolders_cell{p}))); %#ok<CTPCT>
    % Use fullfile to generate cell array of full-path file names
    csvTrialnames_cell = fullfile(repmat({Pfolders_cell{p}},length(matTrials_struct),1),{matTrials_struct.name}');
    clear matTrials_struct
    
    % Load all .mat trial files from imported Pupil tracker data
    matTrials_struct = dir(fullfile(Pfolders_cell{p},sprintf('*.mat',Pfolders_cell{p}))); %#ok<CTPCT>
    % Use fullfile to generate cell array of full-path file names
    matTrialnames_cell = fullfile(repmat({Pfolders_cell{p}},length(matTrials_struct),1),{matTrials_struct.name}');
    clear matTrials_struct
    
    %% Cycle through all trials of each participant
    for t = 1:length(csvTrialnames_cell)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  Section: Load and Organize Data
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Preprocess Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        %% Filter Positional Data
        % Low-pass Butterworth Filter for structure of skeleton markers
        posData = filterKinematicsButter(posData,fps_pos,10.4,40);

       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Calculations Body segments
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Extract Body segment position in Vicon
        % PUPIL SAMPLES FROM EYE 1, is this the right or left one?          ?
        % Create a character list of all marker names
        markerNames = fieldnames(points);
        
        % Initiate Markers
        HeadTori = [];
        HeadUke = [];
        LeftHand = [];
        RightHand = [];
        
        for s = 1:length(markerNames)
            string = markerNames{s};
            % Cycle trough each
            switch string
                case {'Uke1','Uke2','Uke3','Uke4'}
                    HeadUke =  cat(3,HeadUke,points.(string));
                case {'Head1','Head2','Head3','Head4'}
                    % Get all the xyz markers and stack in fourth dimension
                    HeadTori =  cat(3,HeadTori,points.(string));
                    
                case {'LeftHand1','LeftHand2','LeftHand3','LeftHand4'}
                    LeftHand =  cat(3,LeftHand,points.(string));
                case {'RightHand1','RightHand2','RightHand3','RightHand4'}
                    RightHand =  cat(3,RightHand,points.(string));  
                    
                case {'CalibrationCross1', 'CalibrationCross2', ...
                        'CalibrationCross3', 'CalibrationCross4' ...
                        'CalibrationCross5'}
                    CalibrationCross = cat(3,CalibrationCross,points.(string));
            end
        end
        
        % Sum the markers and take mean (e.g., mean(HeadTori(:,:,1:4)))
        % To take the mean of all markers, divide by the number of markers
        % (size(,3)) gives out the number of markers
        average.HeadTori_c =  sum(HeadTori,3)/size(HeadTori,3);
        average.HeadUke_c = sum(HeadUke,3)/size(HeadUke,3);
        average.LeftHand_c = sum(LeftHand,3)/size(LeftHand,3);
        average.RightHand_c = sum(RightHand,3)/size(RightHand,3);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Calculations of Head Vector
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Calculate angle between UkeHead and Hands
        % Create a vector from Head to either hand
        HLeft = average.HeadUke_c - average.LeftHand_c;
        HRight = average.HeadUke_c - average.RightHand_c;
        
        % https://ch.mathworks.com/matlabcentral/answers/328240-calculate-the-3d-angle-between-two-vectors
        for d = 1:fileLength
            HLeftv = HLeft(d,:)'; % Transform the first double into vert vector
            HRightv = HRight(d,:)'; % Same here
            angleHead(d,:) = atan2d(norm(cross(HLeftv,HRightv)),dot(HLeftv,HRightv));
        end
        
        %% Calculate angular values and save in double
        angleTable{w,1} = angle;
        MeanTrials(1,w) = mean(angle);
        MedianTrials(1,w) = median(angle);
        
        
        
        
    end % End of trial loop
    
    % Place calculations for participant here (i.e. average over all trials) 
    boxplotTrials(angleTable, MedianTrials,1,'Boxplot',1,'.png');
    
end % End of participant loop
 
% Place calculations for all participant here (i.e. average over all participants, export data/graphs) 


