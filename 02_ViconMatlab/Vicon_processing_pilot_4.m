%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Skript: Vicon processing Judo data
% Author: Daniel Müller
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
% Requirements:
% 1. BTK-Toolkit: https://code.google.com/archive/p/b-tk/
% 2. .c3d file with segments 'LeftHand', 'RightHand', 'ToriHead', 'UkeHead'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Mise-en-place
close all;
clear all;
clc;
% Add all files in the directory enviornment
addpath(genpath(pwd));
% Set working directory
actualDir = cd;

%% Necessary user input
% Set path to the where the .c3d files are stored
pName = fullfile(pwd,'03_Data', 'Participant');
tName = fullfile(pName, 'Session_1', 'Condition_1');

%% Read C3D
% List all files ending with .c3d stored in the pName directory
dir_struct = dir(fullfile(tName,'*.c3d'));
% Sort the files by name and list the filenames
[filenames,~] = sortrows({dir_struct.name}');
trialnames = regexprep(filenames, '.c3d', ''); % Remove file extension

for w = 1%:length(filenames)
    % Get name of file currently processed
    fName = fullfile(tName,filenames{w});
    % Display name of currently processed file
    disp(sprintf('Currently processing: %s', fName))
    
    %% Use BTK-toolkit
    [points,pointsInfo, fileLength] = btkGetPointsDirect(fName);
    
    %% Interpolate missing data
    % The threshold of missing markers indicates whether the marker will be
    % interpolated (value from 0 to 100). In case of 20, only markers with
    % less than 20 percent missings will be interpolated
    points = interpolateStructFull(points);
    
    %% Filter the interpolated data
    % The butter filter smoothes the data with input arguments
    points_filt = filterKinematicsButter(points,pointsInfo.frequency, ...
        10.5,40);
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Start working with data from each file
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% Create means for segments
    % Look at each marker name and create its values to a matrix for its
    % cluster
    
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
            case {'HeadUke1','HeadUke2','HeadUke3','HeadUke4'}                      
                HeadUke =  cat(3,HeadUke,points.(string));
            case {'HeadTori1','HeadTori2','HeadTori3','HeadTori4'}
                % Get all the xyz markers and stack in fourth dimension
                HeadTori =  cat(3,HeadTori,points.(string));
                
            case {'LeftHand1','LeftHand2','LeftHand3','LeftHand4'}
                LeftHand =  cat(3,LeftHand,points.(string));
            case {'RightHand1','RightHand2','RightHand3','RightHand4'}
                RightHand =  cat(3,RightHand,points.(string));
            otherwise
                
        end
    end
    
    % Sum the markers and take mean (e.g., mean(HeadTori(:,:,1:4)))
    % To take the mean of all markers, divide by the number of markers
    % (size(,3)) gives out the number of markers
    average.HeadTori_c =  sum(HeadTori,3)/size(HeadTori,3);
    average.HeadUke_c = sum(HeadUke,3)/size(HeadUke,3);
    average.LeftHand_c = sum(LeftHand,3)/size(LeftHand,3);
    average.RightHand_c = sum(RightHand,3)/size(RightHand,3);
    
    %% Visualize Markers in case needed
    visualizeMarkers_andMeans(points,average,pointsInfo,fileLength,400,0)
    
    
    %% Create angle between HeadUke and Hands
    % Create a vector from Head to either hand
    HLeft = average.HeadUke_c - average.LeftHand_c;
    HRight = average.HeadUke_c - average.RightHand_c;
   
    % https://ch.mathworks.com/matlabcentral/answers/328240-calculate-the-3d-angle-between-two-vectors
    for d = 1:fileLength
        HLeftv = HLeft(d,:)'; % Transform the first double into vert vector
        HRightv = HRight(d,:)'; % Same here
        angle(d,:) = atan2d(norm(cross(HLeftv,HRightv)),dot(HLeftv,HRightv));
    end
    
    %% Calculate angular values and save in double
    angleTable{w,1} = angle;
    MeanTrials(1,w) = mean(angle);
    MedianTrials(1,w) = median(angle);
    
    %% Get angular rotation of the head
    %   [origin, XYZ_rot, XYZ_rot_cont, rot_direction] = localRot(LF, LB, RF, RB, configuration)
        [origin, XYZ_rot, XYZ_rot_cont, rot_direction] = localRot(HeadUke(:,:,1),HeadUke(:,:,2), HeadUke(:,:,3), HeadUke(:,:,4), 1);
        
   
    %% Exporting rotation to text file
     df_exp = num2cell(XYZ_rot);
    FileName = 'xyzHeadAngle';
    path = fullfile(pwd, '98_OutputUnity\');
    filetype = '.csv';
    filename = [path,FileName,filetype];
    % First is to write diff for unity in first column
    dlmwrite(filename,df_exp,'delimiter',',','newline', 'pc');
        
    
    %% Exporting mean head marker (eye) to text file
    df_exp = num2cell(average.HeadUke_c);
    FileName = 'xyzHeadMean';
    path = fullfile(pwd, '98_OutputUnity\');
    filetype = '.csv';
    filename = [path,FileName,filetype];
    % First is to write diff for unity in first column
    dlmwrite(filename,df_exp,'delimiter',',','newline', 'pc');
    
    %% Export all the head markers
    for z = 1:size(HeadUke,3)
    df_exp = num2cell(HeadUke(:,:,z));
    %% Exporting to text file
    FileName = strcat('xyzHead',num2str(z));
    path = fullfile(pwd, '98_OutputUnity\');
    filetype = '.csv';
    filename = [path,FileName,filetype];
    % First is to write diff for unity in first column
    dlmwrite(filename,df_exp,'delimiter',',','newline', 'pc');
    end  
    
end

% Initialize a figure with all the angle distributions
boxplotTrials(angleTable, MedianTrials,1,'Boxplot',1,'.png');