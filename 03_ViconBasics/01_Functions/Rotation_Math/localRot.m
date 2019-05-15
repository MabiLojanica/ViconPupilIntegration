function [origin, XYZ_rot, XYZ_rot_cont, rot_direction] = localRot(LF, LB, RF, RB, configuration)
%LOCALROT creates a local coordinate system and ultimately defines the 
% degrees of raw and continuous rotation of that system. Here, the axes are
% defined as:
%   x-direction = front-back
%   y-direction = left-right
%   z-direction = down-up
% Generically written to accommodate (1) a 'square' configuration of points 
% (i.e. Right front head, right back head, left front head, left back head) 
% Points DO NOT have to be in a perfect square! Pelvis trapezoid is also ok.
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
%       5. configuration: input 1 or 2 to denote points configured in a (1)square
%           or (2)diamond configuration
%
%   OUTPUTS: 
%       1. origin: origin of the local system as the average of the 4 points
%       2. XYZ_rot: n x 3 local rotation of the given system about the x(roll), 
%           y(pitch), and z(yaw) axes from -180 to 180 degrees
%       3. XYZ_rot_cont: n x 3 local rotation of the given system about the x(roll), 
%           y(pitch), and z(yaw) axes in continuous degrees of rotation 
%       4. rot_direction: direction of rotation, where 1 is right and 0 is left
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
if configuration == 1
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

% Initialize rotation variables
XYZ_rot = zeros(length(coordRot.R),3);
XYZ_rot_cont = zeros(length(coordRot.R),3);

%% Determine Euler angle around the z-axis from generalized rotation matrix
for i = 1:length(coordRot.R)
    [XYZ_rot(i,1),XYZ_rot(i,2), XYZ_rot(i,3)] = decomposeRotation(squeeze(coordRot.R(i,:,:)),1);
end

%% Calculate continuous angle and determine rotation direction
[XYZ_rot_cont(:,1), ~] = makeContinuousAngle(XYZ_rot(:,1),1);
[XYZ_rot_cont(:,2), ~] = makeContinuousAngle(XYZ_rot(:,2),1);
[XYZ_rot_cont(:,3), rot_direction] = makeContinuousAngle(XYZ_rot(:,3),1);

end
