%% WhynotDoIt simple way
% https://en.wikipedia.org/wiki/Spherical_coordinate_system#Cartesian_coordinates

%% Mise-en-place
close all;
clear all;
clc;
% Add all files in the directory enviornment
addpath(genpath(pwd));
% Set working directory
actualDir = cd;

df = load('intermediate.mat', '-ascii');
%% Filter data 
order = 3;
framelen = 121;
df_filt = sgolayfilt(df,order,framelen);

%% select calibration sequence
df = df_filt(2677:end,:);

%% Given the plot, 
% X seems to be yaw. positive x is right, negative is left
% Y seems to be pitch. positive y is down, negative is up

%% azimuth = atan(x/z);
yaw = rad2deg(atan(df(:,1) ./ df(:,3)));
yaw_test = rad2deg(atan(.3 / 2));

%% Inclination
r = sqrt(df(:,1).^2 + df(:,2).^2 + df(:,3).^2); % length of vector
pitch_rot = rad2deg(acos(df(:,2) ./ r));

% for some reason, pitch is rotated 90 degrees
pitch = pitch_rot - pitch_rot(1,1);

%% Export Yaw and Pitch for Unity

% Add to double array
df_deg(:,1) = yaw;
df_deg(:,2) = pitch; 
df_deg_exp = num2cell(df_deg);

% Exporting to text file
FileName = 'YawPitch';

path = fullfile(pwd, '99_OutputUnity\');
filetype = '.csv';
filename = [path,FileName,filetype];

% First is to write diff for unity in first column
dlmwrite(filename,df_deg_exp,'delimiter',',','newline', 'pc');

%% Scatter

return % STOP HERE
h = figure

h = scatter3(0,0,0,'filled','black'); % Origin
hold on
h = scatter3(1,0,0,'filled','b'); % X
h = scatter3(0,1,0,'filled','y'); % y
h = scatter3(0,0,1,'filled','r'); % z

h = xlabel('X');
h = ylabel('Y');
h = zlabel('Z');


for d = 1:size(df,1)
h = scatter3(df(d,1),df(d,2),df(d,3));
drawnow
end

