%% Vicon Integration
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
        %  Load and Organize Data
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
        % Always look first, if the csv is already converted to .mat
        % If not, convert it to .mat and load afterwards
        if ~exists(matTrialnames_cell{t})
            csvData  = xlsread(trialnames_cell{t});
            save(csvData,csvTrialnames_cell{t}, '-ascii');
        end
        
        % Load the entire data from the file
        pupilData = load(csvTrialnames_cell{t}), '-ascii');
        
        % Subset the gaze data. Select normalized gaze vectors xyz
        
        % Select eye confidence
        
        % Select time to get the sampling frequency of pupil (120 odd)
        
        % Check if the loaded file is a calibration file. If so, calculate 
        % the current offset for the gaze vector
        if strcmp(trialnames{t}(6:10), 'cal') == 1
            Calibration = cal;
            vicon = CAL; 
            continue
        end
        fps_mat = 256; % Sampling frequency of Pupil data set
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Preprocess Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        %% Filter Positional Data
        % Low-pass Butterworth Filter for structure of skeleton markers
        posData = filterKinematicsButter(posData,fps_pos,10.4,40);

        %% Filter Eye confidence data
        % How? Threshold?
        % Low-pass Butterworth Filter for structure of skeleton markers
        posData = filterKinematicsButter(posData,fps_pos,10.4,40);
        
        %% Filter gaze data
        % Golay, remove peaks, butter?
        % noise within frame or eye differences?

        %% Resample Data
        % Sample down data collected at higher fps to match that of lower fps
        % Here, mat data sampled down to match positional data.
        csvData = resampleData(fps_mat, fps_pos, csvData)';
        
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
        % Synchronization of the Pupil data and the Vicon data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
        %% Pupil
        % Identify frame where trial starts in Pupil
        % Get frame when eyes are closed and opened again (where trial starts)
        eyesClosed = framenumber;
        startPupil = framenumber2;
        
        %% Vicon
        % Identify frame where trial starts in Vicon
        startVicon = framenumber3;
        
        %% Select data from either
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Calculations of gaze Vector
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
       
        %% Get angular rotation of the head
        % Create a rotation matrix around the center of the head markers   ? Shouldnt be the center
        [origin, XYZ_rot,~, rot_direction] = localRot(HeadUke(:,:,1),HeadUke(:,:,2), HeadUke(:,:,3), HeadUke(:,:,4), 1);
        
        % Get gaze angles from Vector as a difference from first frame
        % Calculate Yaw
        df_diff = df;
        x = df_diff(:,1);
        y = df_diff(:,2);
        ratio = x./y;
        yaw = rad2deg(atan(ratio));
        % yaw(isnan(yaw) == 1) = 0;
        yaw = yaw - yaw(1,1);
        
        % Calculate pitch
        z = df(:,3);
        pitch = rad2deg(atan(z ./ y));
        % pitch(isnan(pitch) == 1) = 0;
        pitch = pitch - pitch(1,1);
        
        % Add to double array
        df_deg(:,1) = yaw;
        df_deg(:,2) = pitch;
        
        
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


