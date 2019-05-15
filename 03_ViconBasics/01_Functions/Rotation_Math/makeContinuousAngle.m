function [cont_angle, rot_direction] = makeContinuousAngle(angle_in, degreesTrue)
%MAKECONTINUOUSANGLE makes angles of rotation continuous and determines the
% direction of rotation. Particularly useful for aggregating multiple rotations 
% (ie. turn 1-> 360 deg, turn 2-> 720 deg, etc.).
%
%   INPUTS:
%       1. angle_in: n x 1 or 1 x n double of angles ranging from (-180:180)
%       2. degreesTrue: 1 if angles are in degrees, anything else for radians
%
%   OUTPUTS:
%       1. cont_angle: n x 1 double of the continuous angle
%       2. rot_direction: since absolute rotation in the positive direction,
%           this variable identifies the original direction of rotation
%           1 = positive direction; 0 = negative direction(that was thus made pos)
%
% Written by:  RK, CH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize for positive turn direction
rot_direction = 1; 

% Convert to degrees if in radians
if degreesTrue ~= 1
    angle_in = angle_in(:) * 180/pi();
end

% Place data in a single column (if it isn't already)
if size(angle_in,1) == 1
    angle_in = angle_in';
end

% Find sharp changes from -180 to 180
delta = [0; diff(angle_in)];
over180_neg2pos = find(delta>180);
over180_pos2neg = find(delta<-180);

cont_angle = angle_in;

% Add/subtract 360 to make angles continuous
for i= 1:length(over180_neg2pos)
    cont_angle(over180_neg2pos(i):end) = cont_angle(over180_neg2pos(i):end)-360;
end

for i= 1:length(over180_pos2neg)
    cont_angle(over180_pos2neg(i):end) = cont_angle(over180_pos2neg(i):end)+360;
end

% Convert back to radians if input was not in degrees
if degreesTrue ~= 1
    cont_angle = cont_angle / 180*pi();
end

% Make all rotations positive, regardless of rotation direction 
if cont_angle(end,1)< 0
    cont_angle = cont_angle*(-1);
    rot_direction = 0; % but note that direction was changed...
end

end