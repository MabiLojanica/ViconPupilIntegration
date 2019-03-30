%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Skript: 
% Author:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
% Requirements:
% 1. BTK-Toolkit: https://code.google.com/archive/p/b-tk/
% 2. .c3d file of baseline bodymarker set
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

for i = 1:length(filenames) 
    % Get name of file currently processed
    fName = fullfile(tName,filenames{i});
    % Display name of currently processed file
    disp(sprintf('Currently processing: %s', fName))
    
    %% Use BTK-toolkit
    [points,pointsInfo, fileLength] = btkGetPointsDirect(fName);
    
    %% Interpolate missing data
    % The threshold of missing markers indicates whether the marker will be
    % interpolated (value from 0 to 100). In case of 20, only markers with
    % less than 20 percent missings will be interpolated
    points = interpolateStruct(points, 100);

    %     %% Filter the interpolated data
    %     % The butter filter smoothes the data with input arguments
    %     points_filt = filterKinematicsButter(points,pointsInfo.frequency, ...
    %         10.5,40);

    
    
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
    
    for i = 1:length(markerNames)
        string = markerNames{i};
        % Cycle trough each
        switch string
            case {'HeadUke1','HeadUke2','HeadUke3','HeadUke4'}
                HeadUke =  cat(3,HeadUke,points.(string));
            case {'MariaHead1','MariaHead2','MariaHead3','MariaHead4'} 
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
    HeadTori_c =  sum(HeadTori,3)/size(HeadTori,3);
    HeadUke_c = sum(HeadUke,3)/size(HeadUke,3);
    LeftHand_c = sum(LeftHand,3)/size(LeftHand,3);
    RightHand_c = sum(RightHand,3)/size(RightHand,3);
    
    
    mean.HeadTori_c = HeadTori_c;
    mean.HeadUke_c = HeadUke_c;
    mean.LeftHand_c = LeftHand_c;
    mean.RightHand_c = RightHand_c;
        
HeadUke_c = ones(fileLength,3);
mean.HeadUke_c = ones(fileLength,3);
    
    vLeft = HeadUke_c - LeftHand_c;
    vRight = HeadUke_c - RightHand_c;

    
    % https://ch.mathworks.com/matlabcentral/answers/16243-angle-between-two-vectors-in-3d
    for i = 1:fileLength
    angle(i,:) = atan2(norm(cross(vLeft(i,:),vRight(i,:))), dot(vLeft(i,:),vRight(i,:)));
    end
    % Radian to degree
    angle = angle*(180/pi);
    
    % plot(angle)
    
    visualizeMarkers(mean,pointsInfo,fileLength,4000,vLeft,vRight)
 
end




