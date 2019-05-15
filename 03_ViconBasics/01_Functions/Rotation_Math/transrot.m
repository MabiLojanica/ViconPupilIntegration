function [M,d]=transrot(x,y)
%TRANSROT calculates the rotation matrix and translation vector between given
% marker configurations.
%
%  INPUTS:
%       1. x: 3 x n matrix with n markers in columns and marker x-y-z-coordinates
%           in rows.
%       2. y: the same n markers in a different position and orientation. y
%           must be the same size as x.
%   
%   OUTPUTS:
%       1. M: rotation matrix
%       2. d: translation vector
%
%   Together, M and d transform x into THE BEST FIT of y. Importantly, x and 
%   y do not have to be congruent.
%
% Written by: RvdL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determine how many markers are in our marker sets
nm = size(x,2); % each column should contain a marker.

% Singular Value Decomposition
[U,S,V]=svd(((y-(mean(y,2))*ones(1,nm))*(x-(mean(x,2))*ones(1,nm))'));

% Calculate rotation matrix
M=U*V';

if det(M)<0
    M=U*diag([1,1,-1])*V';
end

% Calculate translation vector
d=(mean(y,2))-M*(mean(x,2));

end