%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Skript: Gaze Angle relative to origin
% Author: Daniel Müller
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
% Requirements:
% TBA
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
fPath = fullfile(pwd,'01_GazeDataRaw','gaze_positions_2019_03_28_002.csv');
fPath = fullfile(pwd,'01_GazeDataRaw','gaze_positions_001.csv');
df = xlsread(fPath,'M:O');
% 
% % Workaround: save to shorten reading
save('intermediate.mat','df', '-ascii');
df = load('intermediate.mat', '-ascii');

%% Dirty filtering, with a given MovingAverage of frames
% nMovingAverage = 100;
% B = 1/nMovingAverage*ones(10,1);
% df_filt= filter(B,1,df(:,1));

%% Visualize in Matlab
% visualizeVectors (df, 120 ,1783,1)

%% Export for Unity
df_exp = num2cell(df);

%% Exporting to text file
FileName = 'xyzNormal';

path = fullfile(pwd, '99_OutputUnity\');
filetype = '.csv';
filename = [path,FileName,filetype];

% First is to write diff for unity in first column
dlmwrite(filename,df_exp,'delimiter',',','newline', 'pc');


