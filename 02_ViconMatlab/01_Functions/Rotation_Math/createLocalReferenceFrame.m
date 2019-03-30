function [R] = createLocalReferenceFrame(xDir, yDir, zDir)
%CREATELOCALREFERENCEFRAME creates a local reference frame, with the assumption
% that:
%   x-direction = front-back,
%   y-direction = left-right
%   z-direction = cross( x-dir, y-dir)
%   >> y-direction corrected = cross( z-dir, x-dir)
%
%   INPUTS:
%       1. origin: n x 3 double containing the x-y-z 3D position of the origin
%       2. xDir: n x 3 double for the x-direction vector
%       3. yDir: n x 3 double for the y-direction vector
%       4. yDir: n x 3 double for the z-direction vector
%       * All inputs should be the same size.
%
%   OUTPUTS:
%       1. R: n x 3 x 3 local reference frame 
%
% Written by: RK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Normalize all vectors 
xDirNorm = (xDir(:,1).^2 +xDir(:,2).^2 +xDir(:,3).^2).^0.5;
xDirNorm = [xDirNorm xDirNorm xDirNorm];
xDir = xDir ./ xDirNorm;

zDirNorm = (zDir(:,1).^2 +zDir(:,2).^2 +zDir(:,3).^2).^0.5;
zDirNorm = [zDirNorm zDirNorm zDirNorm];
zDir = zDir ./ zDirNorm;

yDirNorm = (yDir(:,1).^2 +yDir(:,2).^2 +yDir(:,3).^2).^0.5;
yDirNorm = [yDirNorm yDirNorm yDirNorm];
yDir = yDir ./ yDirNorm;

%% Save local reference frame along every dimension 
R(:,:,1) = [xDir(:,1) yDir(:,1)  zDir(:,1)];
R(:,:,2) = [xDir(:,2) yDir(:,2)  zDir(:,2)];
R(:,:,3) = [xDir(:,3) yDir(:,3)  zDir(:,3)];

end
