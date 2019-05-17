%% Vicon Integration Head Orientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
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
Pfolders_cell = fullfile(repmat({DataDir},length(Pfolders_struct),1),{Pfolders_struct.name}');
clear Pfolders_struct tmp

%% Cycle through all participants
for p = 1: length(Pfolders_cell)
    
    % Load all .c3d trial files (Having the string Trial*.c3d in it
    c3dTrials_struct = dir(fullfile(Pfolders_cell{p},'Session1',sprintf('Trial*.c3d',Pfolders_cell{p}))); %#ok<CTPCT>
    % Use fullfile to generate cell array of full-path file names
    c3dTrialnames_cell = fullfile(repmat({Pfolders_cell{p}},length(c3dTrials_struct),1),'Session1',{c3dTrials_struct.name}');
    % Save trial names
    trialnamesExtended = {c3dTrials_struct.name}';
    trialnames = regexprep(trialnamesExtended, '.c3d', '');% Remove file extension from trial name
    clear trialnames_struct
    
    
    %% Cycle through all trials of each participant
    for t = 1:length(c3dTrialnames_cell)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  Section: Load and Organize Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Use BTK-toolkit to read the c3d Files
        [points,pointsInfo, fileLength] = btkGetPointsDirect(c3dTrialnames_cell{t});
        
        %% Interpolate missing data
        % The threshold of missing markers indicates whether the marker will be
        % interpolated (value from 0 to 100). In case of 20, only markers with
        % less than 20 percent missings will be interpolated
        points = interpolateStructFull(points);
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Preprocess Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Filter the interpolated data
        % The butter filter smoothes the data with input arguments
        points_filt = filterKinematicsButter(points,pointsInfo.frequency, ...
            10.5,40);
        clear points
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Calculations Body segments
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Extract Body segment position in Vicon
        markerNames = fieldnames(points_filt); % Make a list of the marker names
        
        % Initiate Markers
        ToriHead = [];
        UkeHead = [];
        LeftHand = [];
        RightHand = [];
        CalibrationCross = [];
        
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
                    CalibrationCross = cat(3,CalibrationCross,points_filt.(string));
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Calculations of Head Vector
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Calculate angle between UkeHead and Hands
        % Create a vector from Head to either hand
        HeadLeft = average.UkeHead_c - average.LeftHand_c;
        HeadRight = average.UkeHead_c - average.RightHand_c;
        
        %% Check if the trial contains any data
        if (isempty(HeadLeft) == 1) || (isempty(HeadRight) == 1)
            disp(sprintf('Trial empty: Participant %d, Trial: %d', p, t));
            
            % Fill angle head with NaNs
            angleHead = NaN(fileLength,1);
        else
            
            % In case its not empty, calculate angles
            % https://ch.mathworks.com/matlabcentral/answers/328240-calculate-the-3d-angle-between-two-vectors
            for d = 1:fileLength
                HLeftv = HeadLeft(d,:)'; % Transform the first double into vert vector
                HRightv = HeadRight(d,:)'; % Same here
                angleHead(d,:) = atan2d(norm(cross(HLeftv,HRightv)),dot(HLeftv,HRightv));
            end

            
            clear HLeft HRight HLeftv HRightv average CalibrationCross LeftHand RightHand UkeHead ToriHead d
            
        end
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Trim Data to start frame (open eyes) and end frame (grip)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
        %% Define start frame
        startFrame = 1;
        
        %% Define end frame
        grip = startFrame + 500;
        
        % Cut data at start and end frames
        cutAngleHead = angleHead(startFrame:grip,1);
        
        
        % Normalized length
        NormLength = 100;
        % Now squeeze the angular data into the normalized array
        angleHeadPct = resample(cutAngleHead,NormLength,length(cutAngleHead));
        
        clear angleHead cutAngleHead grip HeadLeft HeadRight NormLength startFrame
      
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Save Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          
        exportNames{1,t} = trialnames{t};
        exportData(:,t) = angleHeadPct;
        
    end % End of trial loop
    
 
    exportNamesPerParticipant(1,t) = horzcat(exportNames,exportNames);
    exportDataPerParticipant = horzcat(exportData,exportData);
    
    
    
end % End of participant loop





% Place calculations for all participant here (i.e. average over all participants, export data/graphs)
T = table(exportDataAll);

