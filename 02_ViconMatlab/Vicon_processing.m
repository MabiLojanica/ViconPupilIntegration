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
pName = fullfile(pwd,'02_Data');

%% Read C3D
% List all files ending with .c3d stored in the pName directory
dir_struct = dir(fullfile(pName,'*.c3d'));
% Sort the files by name and list the filenames
[filenames,~] = sortrows({dir_struct.name}');

for i = 5 %:length(filenames)                                              % Debug                                      
    % Get name of file currently processed
    fName = fullfile(pName,filenames{i});
    % Display name of currently processed file
    disp(sprintf('Currently processing: %s', fName))
    
    %% Use BTK-toolkit
    [points,pointsInfo, fileLength] = btkGetPointsDirect(fName);
    
    %% Interpolate missing data
    % Because data contains unlabeled points for first and last frame, only
    % markers with less than 20 percent missings are interpolated
    points = interpolateStruct(points, 20);
    

    
    
    %% Visualize
    visualizeMarkers(points,pointsInfo,fileLength); % Hit ESCAPE to close
    
    
        %% Filter the interpolated data
    % The butter filter smoothes the data with input arguments
    points_filt = filterKinematicsButter(points,pointsInfo.frequency, ...
        10.5,40);
    % Plot Filtered and unfiltered data against each other
    figure1 = plotFilter(points, points_filt,pointsInfo, fileLength, ...
        fName, 1, actualDir, 'LeftHand2')

    
end




