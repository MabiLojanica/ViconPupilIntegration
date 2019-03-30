function [x,y,z] = decomposeRotation(R, degTrue)
%DECOMPOSEROTATION decomposes a generalized rotation matrix into Euler angles
% of yaw, pitch, and roll - which are counter clockwise rotations about the
% z, y, and x-axes, respectively. 
%
%   INPUTS:
%       1. R: 3 x 3 generalized rotation matrix
%       2. degTrue: 1 for an output in degrees, else radians
%
%   OUTPUTS:
%       1. x: angle of 'roll' around the x-axis (front-back) 
%       2. y: angle of 'pitch' around the y-axis (left-right) 
%       3. z: angle of 'yaw' around the z-axis (bottom-top) 
%
% Written by: RK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if degTrue % to convert output to degrees
    x = 180/pi() * atan2(R(3,2), R(3,3));                               % roll(gamma)
    y = 180/pi() * atan2(-R(3,1), sqrt(R(3,2)*R(3,2) + R(3,3)*R(3,3))); % pitch(beta)
    z = 180/pi() * atan2(R(2,1), R(1,1));                               % yaw(alpha)
else
    x = atan2(R(3,2), R(3,3));                              % roll(gamma)
    y = atan2(-R(3,1), sqrt(R(3,2)*R(3,2) + R(3,3)*R(3,3)));% pitch(beta)
    z = atan2(R(2,1), R(1,1));                              % yaw(alpha)
end

end