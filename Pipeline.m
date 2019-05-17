%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 'Passing Accuracy Test'
%
% Requirements:
% 1. BTK-Toolkit: https://code.google.com/archive/p/b-tk/
% 2. .c3d files with Unlabeled passing data
%
% Issues:
%   - Issue 1 is a filtering issue
%   - Issue 2 is a ball velocity measurement issue
%
% This pipeline template assumes the following organization.
%       There is one folder for the analysis containing:
%       - A folder with all data, organized with one folder for each
%         participant that contains all trials of that participant
%           - participant folders labeled 'p01', 'p02', 'p03', etc.
%       - A folder containing all MATLAB functions used in the pipeline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tmp = matlab.desktop.editor.getActive; % Gets the name of current script
cd(fileparts(tmp.Filename)); % Changes directory to current script
addpath(genpath(cd));% Add all files in subfolders to path
close all
clear all  %#ok<CLALL>
clc

% Initiate variables 
angleAppend = [];
velocityAppend = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make inventory of data directory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Go to repository folder
addpath(genpath(pwd));

% Or simply define data folder location:
DataDir = fullfile(pwd,'02_Data');

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
    
    %% Cycle through all trials of each participant
    for t = 1:length(c3dTrialnames_cell)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  Section: Load and Organize Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% c3d Data Initialization
        % Turn warnings off for btk toolbox
        warning('OFF', 'btk:ReadAcquisition');
        % Put a handle on the c3d file (using the btk toolbox)
        h = btkReadAcquisition(c3dTrialnames_cell{t});
        
        %% c3d Positional Data
        % Extract positional data and info from c3d file
        [posData, pointsInfo] = btkGetPoints(h);
        fps_pos = pointsInfo.frequency; % MoCap Sampling Frequency
        clear h
        
        % ORGANIZE POSITIONAL DATA
        % Order fields alphabetically to ensure same marker order for each
        % trial- may be necessary for filtering later on...
        markerNames = fieldnames(posData);
        trialLength = length(posData.(markerNames{1})); % Get trial length
        
        % Set all zero values to NaN
        for q = 1:length(markerNames)
            posData.(markerNames{q})(posData.(markerNames{q}) == 0) = NaN;
            % Get sum of NaN of each unlabeled marker
            missingPct.(markerNames{q}) = (sum(isnan(posData.(markerNames{q})(:,1))) / trialLength) *100;
        end
        clear q
        
        % Now that missing percent of markers is known, order the fields in
        % struct based on this value
        [~, idxs] = sort(cell2mat(struct2cell(missingPct)));
        missingPct = orderfields(missingPct, idxs); % Get index for missing values and rearrange missing Pct struct based on that
        posData = orderfields(posData,missingPct); % Order the fields in pos Data to match the missing percentages from missingPctStruct
        markerNames = fieldnames(posData); % Get the reordered Marker names
        
        clear idxs
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Preprocess Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Get the ball trajectory out of the unlabeled markers
        % Take all markers who have at least 10 percent of the data
        % Take all markers where the ball is on the ground (z is below 0.3)
        
        % initialize a counter for timeseries completeness
        completeness = 0; % init
        fieldcount = 0; % init
        ball = NaN(trialLength,3);
        
        while completeness < 90
            fieldcount = fieldcount + 1; % Go to next field in struct
            % Check how many values are missing for the marker
            if missingPct.(markerNames{fieldcount}) > 90
                break % Markers with less than 10 % data are discarded
            end
            
            % Only get the markers on the ground on ball z height.
            % Calculate the mean height of marker
            meanZ = nanmean(posData.(markerNames{fieldcount})(:,3));
            
            if  (meanZ >= 0) & (meanZ <= 0.3);
                % Create an array 'ball' with the timeseries data
                missingidx = isnan(ball); % Get an index of all the missings
                % For all the indexes, substitute the value of the marker
                ball(missingidx) = posData.(markerNames{fieldcount})(missingidx);
                
                % Get the completeness of the ball array
                completeness = ((trialLength - sum(isnan(ball(:,1)))) / trialLength ) *100;
            end
            
            % End the while loop in case the markers arent sufficient for
            % 90 percent completeness
            if fieldcount >= length(markerNames)
                sprintf('Warning: The completeness is: %.0f percent maximum on trial %s',completeness, trialnames{t})
                break
            end
        end
        
        clear meanZ missingidx missingPct fieldcount completeness
        
        
        %% Interpolate missing marker points
        ballInt = naninterp(ball);
        
        %% Filter Positional Data
        % Low-pass Butterworth Filter for structure of skeleton markers
        % **Issue1**: Filter is not chosen well
        ballf = butterArray(ballInt,'off',0.01,0.3);
        clear ballInt ball
    
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Calculate Ball events
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % At the right wall of the lab, a point is defined (wall_pos),
        % around which a circle is drawn (radius = threshold_m).
        % Each time the ball exits the radius - rolling to the participant (Roll_idx),
        % there is an expected kick (pass_event) happening within the next second (timeThreshold).
        
        % Define pass circle at the wall
        wall_pos = [3 0]; % Define a spot at the right wall
        ball_pos = [ballf(:,1) ballf(:,2)];
        
        delta_vec =  ball_pos - wall_pos;
        eucl_dist = (delta_vec(:,1).^2 + delta_vec(:,2).^2).^0.5;
        
        % Find events where  distance is less than 200 cm
        threshold_m = 2;
        ball_condition = eucl_dist < threshold_m;
        
        % Every time the ball gets in the zone, value is +1, every time the
        % ball gets out of the zone, value is -1
        ballCrossesZone = [0, diff(ball_condition)']';
        
        % Find all the events where the ball exits the radius
        [Roll_idx ~] = find(ballCrossesZone == 1);
        
        clear ballCrossesZone ball_condition threshold eucl_dist delta_vec ball_pos wall_pos
        
        %% Check the data for kicks within the following second
        % For loop for all the kicks in Roll_idx
        % Define threshold: How many frames after the ball crosses the zone
        % is the kick to be expected?
        timeThreshold = 400; % Within 200 frames
        for r = 1:length(Roll_idx)
            passWindow = ballf(Roll_idx:(Roll_idx+timeThreshold),:);
            
            % Find when the ball changes in Y direction, indicating a kick
            % forward
            forward = diff(passWindow(:,2));
            % Find the frame where the forward velocity is bigger than 0.005
            kickEvent = find(forward > 0.005,1, 'first');
            if isempty(kickEvent) == 1
                break
            end
            kickEvent = kickEvent + Roll_idx(r); % The kick event is added to the Roll event frame detected.
            clear forward
            
            %% Calculate angle to target
            % A target is at the front wall, being at a relative offset to the
            % origin at (Target[x y]).
            % The angle is calculated as the ball reaches a point one meter in
            % front of the target (TargetCutoff)
            
            Target = [0 6]; % Target is centrally on the front screen (x) and y meters from origin
            TargetCutoff = [0 Target(2)-1]; % Get an imaginary point which is needed to calculate the angle of the pass
            PassPos = ballf(kickEvent,1:2); % Get x and y value of passing location
            
            % Find the frame when pass is at Target Cutoff
            PassAtTargetCutoff = find(passWindow(:,2) > 5,1, 'first');
            PassEndPosition = [passWindow(PassAtTargetCutoff,1) passWindow(PassAtTargetCutoff,2)]; % Position of the ball when crossing target cutoff line
            
            %% Angle between PassPos and Target
            % Its the tangens from the x difference (far) between target and
            % kicking position; and y, being the y difference (adjacent)
            % between target and kicking position
            if PassPos(1)>=0
                far = (PassPos(1) - PassEndPosition(1));
            else
                far = (PassPos(1) + PassEndPosition(1));
            end
            
            if PassPos(2)>=0
                adjacent = (PassPos(2) - PassEndPosition(2));
            else
                adjacent = (PassPos(2) + PassEndPosition(2));
            end
            
            % Yield angle
            angle = rad2deg(atan(far/adjacent));
            angleAbsolute = abs(angle);
            clear adjacent far PassEndPosition Target
           
            
            %% Get passing velocity
            % Get frame and position when the ball has traveled one meter
            % in x direction from the passeur
            VStartFrame = find(passWindow(:,2) > (PassPos(2)+1),1, 'first');
            VStartPosition = [passWindow(VStartFrame,1) passWindow(VStartFrame,2)];
            VEndPosition = [passWindow(PassAtTargetCutoff,1) passWindow(PassAtTargetCutoff,2)];
            
            delta_vec =  VEndPosition - VStartPosition;
            eucl_dist = (delta_vec(1).^2 + delta_vec(2).^2).^0.5;
            
            delta_time = (PassAtTargetCutoff - VStartFrame)/fps_pos; % Difference of time elapsed in seconds of pass between both thresholds
            
            % Yield velocity
            velocity = (eucl_dist / delta_time)*3.6;
            
            clear passWindow PassAtTargetCutoff VStartFrame VStartPosition VEndPosition delta_vec eucl_dist delta_time TargetCutoff threshold_m KickEvent PassPos
            
            
            %% Archive Data
            angleAppend = horzcat(angleAppend,angleAbsolute);
            velocityAppend = horzcat(velocityAppend,velocity);
            
            
            
        end
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Archive trial data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       

        figure('visible','on')
        scatter(velocityAppend,angleAppend)
        title('Dispersion Diagram')
        xlabel('Velocity [km/h]')
        ylabel('Angular error [degree]')
        lsline
        
        
        
        
        
        
        % Put the ball trajectory data into array
        %         archive.(trialnames{t}) = ball;
        %         plot3(ball(:,1),ball(:,2),ball(:,3));
        %         xlabel('X')
        %         ylabel('Y')
        %         zlabel('Z')
        %         %% Calculate angular values and save in double

        
        %         MeanTrials(1,w) = mean(angle);
        %         MedianTrials(1,w) = median(angle);
        
        
        clear posData missingPct timeThreshold threshold_m Roll_idx passWindow kickEvent%Clear the structs for the next trial
    end % End of trial loop
    
    % Place calculations for participant here (i.e. average over all trials)
    %     boxplotTrials(angleTable, MedianTrials,1,'Boxplot',1,'.png');
    
end % End of participant loop

% Place calculations for all participant here (i.e. average over all participants, export data/graphs)


