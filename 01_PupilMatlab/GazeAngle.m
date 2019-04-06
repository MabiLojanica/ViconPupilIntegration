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
fPath = fullfile(pwd,'01_GazeDataRaw','gaze_positions_001.csv');
df = xlsread(fPath,'M:O');
conf = xlsread(fPath,'C:C');

% Workaround: save to shorten reading
save('intermediate.mat','df', '-ascii');
df = load('intermediate.mat', '-ascii');


%% Filter data 
order = 3;
framelen = 121;
df_filt = sgolayfilt(df,order,framelen);


%% Arbitrary
% df = df_filt(2717+1200:end,:);

%% Visualize in Matlab
visualizeVectors (df, 120 ,length(df),1,0);

%% Get gaze angles from Vector as a difference from first frame
% Calculate Yaw
df_diff = df;
x = df_diff(:,1);
y = df_diff(:,2);
ratio = x./y;
yaw = rad2deg(atan(ratio));
yaw(isnan(yaw) == 1) = 0;
yaw = yaw - yaw(1,1);

% Calculate pitch
z = df(:,3);
pitch = rad2deg(atan(z ./ y));
pitch(isnan(pitch) == 1) = 0;
pitch = pitch - pitch(1,1);

% Add to double array
df_deg(:,1) = yaw;
df_deg(:,2) = pitch; 


%% Export Yaw and Pitch for Unity
df_deg_exp = num2cell(df_deg);

% Exporting to text file
FileName = 'YawPitch';

path = fullfile(pwd, '99_OutputUnity\');
filetype = '.csv';
filename = [path,FileName,filetype];

% First is to write diff for unity in first column
dlmwrite(filename,df_deg_exp,'delimiter',',','newline', 'pc');




%% Export vector3 to Unity
df_exp = num2cell(df);
% Exporting to text file
FileName = 'xyzNormal';
path = fullfile(pwd, '99_OutputUnity\');
filetype = '.csv';
filename = [path,FileName,filetype];

% First is to write diff for unity in first column
dlmwrite(filename,df_exp,'delimiter',',','newline', 'pc');


