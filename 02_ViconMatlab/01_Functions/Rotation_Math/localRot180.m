function [origin, X_rot, Y_rot, Z_rot, rot_direction] = localRot180(LF, LB, RF, RB, diamondyesno)
%LOCALROT180 creates a local coordinate system and ultimately defines the 
% rotation of that system(-180 to 180 deg). Here, the axes are defined as
%   x-direction = front-back
%   y-direction = left-right
%   z-direction = down-up
% Generically written to accommodate (1) a 'square' configuration of points 
% (i.e. Right front head, right back head, left front head, left back head) 
% Points DO NOT have to be in a perfectly square orientation! Pelvis 
% trapezoid is also ok.
%   Square configuration:
%           (LF)X         X(RF)
%
%           (LB)X         X(RB)
% Can additionally accommodate (2) a 'diamond' configuration of points along 
% the X and Y axes. The shoulder girdle of a Plug-in Gait model is an example 
% of such a configuration (i.e. LF = CLAV, LB = LSHO, RF = RSHO, RB = C7)
%   Diamond configuration:
%            (LF)X
%       (LB)X         X(RF)
%                X(RB)
%
%   INPUTS: 
%       1-4. LF, LB, RF, RB: 3D positional data of 4 points to define a local
%               coordinate system. See figures above.
%       5. diamondyorn: input 1 or 2 to denote points configured in a (1)square
%           or (2)diamond configuration
%
%   OUTPUTS: 
%       1. origin: origin of the local system as the average of the 4 points
%       2. X_rot: n x 1 local 'roll' of the given system about the x-axis (front-back)
%       3. Y_rot: n x 1 local 'pitch' of the given system about the y-axis (left-right)
%       4. Z_rot: n x 1 local 'yaw' of the given system about the z-axis (bottom-top)
%       5. rot_direction: direction of rotation, where 1 is right and 0 is left
%           (in a right handed y-left-right, z-up coordinate system)
%
% Author: CH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Calculate the origin
% Concatenate all markers along 3rd dimension
Origin3D= cat(3,LF,LB,RF,RB);

% Calculate the center/average position of the four
origin = nanmean(Origin3D,3);

%% Define local coordinate systems
if diamondyesno == 1
    XDir = ((LF - LB) + (RF - RB)) ./2;
    YDir = ((LF - RF) + (LB - RB)) ./2;
else
    XDir = LF - RB;
    YDir = LB - RF;
end

ZDir = cross(XDir,YDir);
YDir = cross(ZDir,XDir);

%% Create local reference frame: [ rotation matrix,origin ] 
[coordRot.R] = createLocalReferenceFrame(XDir, YDir, ZDir);

% Initialize rotation variable
X_rot = zeros(length(coordRot.R),1);
Y_rot = zeros(length(coordRot.R),1);
Z_rot = zeros(length(coordRot.R),1);

%% Determine Euler angle around the z-axis from generalized rotation matrix
for i = 1:length(coordRot.R)
    [ X_rot(i),Y_rot(i), Z_rot(i)] = decomposeRotation(squeeze(coordRot.R(i,:,:)),1);
end

%% Calculate continuous angle around the Z axis
[~, rot_direction] = makeContinuousAngle(Z_rot,1);

end
