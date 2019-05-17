%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Vicon Integration Head Orientation
%
% Requirements:
% 1. BTK-Toolkit: https://code.google.com/archive/p/b-tk/
% 2. .c3d file with segments 'LeftHand', 'RightHand', 'ToriHead', 'UkeHead'
%    'ToriHead', 'CalibrationCross'
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
tmp = matlab.desktop.editor.getActive; % Gets the name of current script
cd(fileparts(tmp.Filename)); % Changes directory to current script
cd ..\ % Navigate to the main folder of the directory
addpath(genpath(cd));% Add all files in subfolders to path

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make inventory of data directory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make a link to where the data is stored
DataDir = fullfile(pwd,'04_DataJudo\Vicon');

% Load all participant folders
Pfolders_struct = dir(fullfile(DataDir,'P*'));
% Generate cell array of full-path folder names
Pfolders_cell = fullfile(repmat({DataDir},length(Pfolders_struct),1), ...
    {Pfolders_struct.name}');
clear Pfolders_struct tmp

% Create an export variable for export to R
exportAllData = [];



%% Cycle through all participants
for p = 1: length(Pfolders_cell)
    
    % Load all .c3d trial files (Having the string Trial*.c3d in it)
    c3dTrials_struct = dir(fullfile(Pfolders_cell{p},'Session1', ...
        sprintf('Trial*.c3d',Pfolders_cell{p})));
    % Use fullfile to generate cell array of full-path file names
    c3dTrialnames_cell = fullfile(repmat({Pfolders_cell{p}}, ...
        length(c3dTrials_struct),1),'Session1',{c3dTrials_struct.name}');
    % Save trial names
    trialnamesExtended = {c3dTrials_struct.name}';
    % Remove file extension from trial name
    trialnames = regexprep(trialnamesExtended, '.c3d', '');
    clear trialnames_struct
    
    
    %% Cycle through all trials of each participant
    for t = 1:length(c3dTrialnames_cell)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  Section: Load and Organize Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Use BTK-toolkit to read the c3d Files
        [points,pointsInfo, fileLength] = ...
            btkGetPointsDirect(c3dTrialnames_cell{t});
        
        %% Interpolate missing data
        % The threshold of missing markers indicates whether the marker
        % will be interpolated (value from 0 to 100). In case of 20, only
        % markers with less than 20 percent missings will be interpolated
        points = interpolateStructFull(points);
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Preprocess Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Filter the interpolated data
        % The butter filter smoothes the data with input arguments
        points_filt = ...
            filterKinematicsButter(points,pointsInfo.frequency,10.5,40);
        clear points
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Calculations Body segments
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Extract Body segment position in Vicon
        markerNames = fieldnames(points_filt); % Make a list of the markers
        
        % Initiate Markers as empty variables before cycling through data
        ToriHead = [];
        UkeHead = [];
        LeftHand = [];
        RightHand = [];
        CalibrationCross = [];
        
        % Add the markers (1-n) together to a cluster
        for s = 1:length(markerNames)
            string = markerNames{s};
            % Cycle trough each
            switch string
                case {'UkeHead1','UkeHead2','UkeHead3','UkeHead4'}
                    UkeHead =  cat(3,UkeHead,points_filt.(string));
                    % Get all the xyz markers and stack in fourth dimension
                case {'ToriHead1','ToriHead2','ToriHead3','ToriHead4'}
                    ToriHead =  cat(3,ToriHead,points_filt.(string));
                case {'LeftHand1','LeftHand2','LeftHand3','LeftHand4'}
                    LeftHand =  cat(3,LeftHand,points_filt.(string));
                case {'RightHand1','RightHand2','RightHand3','RightHand4'}
                    RightHand =  cat(3,RightHand,points_filt.(string));
                case {'CalibrationCross1', 'CalibrationCross2', ...
                        'CalibrationCross3', 'CalibrationCross4' ...
                        'CalibrationCross5'}
                    CalibrationCross = cat(3,CalibrationCross, ...
                        points_filt.(string));
            end
        end
        
        
        % Sum the markers and take mean (e.g., mean(HeadTori(:,:,1:4)))
        % To take the mean of all markers, divide by the number of markers
        % (size(,3)) gives out the number of markers
        average.ToriHead_c =  sum(ToriHead,3)/size(ToriHead,3);
        average.UkeHead_c = sum(UkeHead,3)/size(UkeHead,3);
        average.LeftHand_c = sum(LeftHand,3)/size(LeftHand,3);
        average.RightHand_c = sum(RightHand,3)/size(RightHand,3);
        
        clear RightHand LeftHand ToriHead UkeHead s
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Calculations of Head Vector
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Calculate angle between UkeHead and Hands
        % Create a vector from Head to either hand
        HeadLeft = average.UkeHead_c - average.LeftHand_c;
        HeadRight = average.UkeHead_c - average.RightHand_c;
        
        %% CATCH: Check if the trial contains any data
        if (isempty(HeadLeft) == 1) || (isempty(HeadRight) == 1)
            disp(sprintf('Trial empty: Participant %d, Trial: %d', p, t));
            % Fill angle head with NaNs
            exportData(:,t) = NaN(100,1);
            continue
        end
        
        % In case its not empty, calculate angle between head and hands
        for d = 1:fileLength
            % Transpond the double vectors
            HLeftv = HeadLeft(d,:)';
            HRightv = HeadRight(d,:)';
            % Calculate the angle between the two vectors
            angleHead(d,:) = atan2d(norm(cross(HLeftv,HRightv)), ...
                dot(HLeftv,HRightv));
        end
        
        clear HLeft HRight HLeftv HRightv CalibrationCross ...
            UkeHead ToriHead d
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Trim Data to start frame (open eyes) and end frame (grip)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Define start and end frame of the trial
        % Define start frame when participants opens eyes
        startFrame = 1;
        
        % Distance between two 3D point arrays
        distance = vecnorm(average.LeftHand_c - average.RightHand_c,2,2);
        
        % Find events where  distance is less than 200 cm
        threshold_cm = 180;
        start = distance < threshold_cm;
        
        % Define time of clap
        clap = find(start,1,'first');
        
        % CATCH: IF NO CLAP IS FOUND:
        if isempty(clap) == 1
            clap = 1;
             disp(sprintf('Clap not found: Participant %d, Trial: %d', p, t))
        end
        
        %% When is the first time the participant starts moving after clap?
        % Get the movement velocity of Ukes head
        delta_dist = (average.UkeHead_c(:,1).^2+ average.UkeHead_c(:,2).^2 +average.UkeHead_c(:,3).^2).^.5;
        % Get the velocity (m/s) from the clap on until the end of the
        % trial
        velUke = ([0; diff(delta_dist(clap:end))]*pointsInfo.frequency)/100;
        % Take the absolute velocities of the head
        velUke = abs(velUke);
        
        % Find the moment Uke moves head with more than 1 meter per second
        threshold_vel = 1; 
        % Has Uke started moving?
        startMovement = velUke > threshold_vel;
        
        % Define time of movement initiation
        startFrameOffset = find(startMovement,1,'first');
        % The true start frame is defined as an offset from when the clap
        % happened:
        startFrame = startFrameOffset + clap;
        
        clear average delta_vec start threshold_m treshold_ms
  
        % CATCH: IF NO MOVEMENT INITIATION IS FOUND
        if isempty(startFrame) == 1
            startFrame = clap;
             disp(sprintf('Movement initiation not found: Participant %d, Trial: %d', p, t))
        end
        
        
        %% Define end frame
        endFrame = startFrame + 500;
        % Cut data at start and end frames
        cutAngleHead = angleHead(startFrame:endFrame,1);
        uncutAngleHead = angleHead(:,1);
        
        
%         %% PLOTTING TO DEBUG
%         plot(uncutAngleHead)
%         line([startFrame startFrame], [-120 120])
%         line([clap clap], [-50 50])
%         hold on
%         plot(velUke,'r')
%         
        
        %% Normalize length to be 1:100 for each trial
        NormLength = 100;
        % Now squeeze the angular data into the normalized array
        angleHeadPct = resample(cutAngleHead,NormLength,length(cutAngleHead));
        
        clear angleHead cutAngleHead endFrame HeadLeft HeadRight ...
            NormLength startFrame
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Save Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Concatenate the results of all trials together
        exportNames{1,t} = trialnames{t};
        exportData(:,t) = angleHeadPct;
        
    end % End of trial loop
    
    % Concatenate the trials of all participants together
    exportAllData = horzcat(exportAllData,exportData);
    
    
    
end % End of participant loop


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Export the data to a .mat file
save 05_RStatistics/AllTrials.mat exportAllData


