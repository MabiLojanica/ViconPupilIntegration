function [new_loc] = createImaginaryMarker (ref_loc,ref_markers,ref_markersNext)
%CREATEIMAGINARYMARKER calculates the position of an imaginary marker (or Joint
% Center) for one frame. This function could also be used to fill gaps of 
% a rigid body cluster. 
%
%   INPUTS:
%       1. ref_loc: The reference location of the marker to create, determined 
%           from the mean position, geometrically calculated (ie.knee joint 
%           position = average between 2 markers on either side of the knee in 
%           Calibration trial), or simply the last trial the marker was present.
%       2. ref_markers: Markers that create a rigid body with the created 
%           imaginary marker.It is best if these markers are on the same segment.
%           The  t= 0 position should be the average position of the markers 
%           over the whole trial, which feeds into the first frame(t =1) of 
%           the trial
%       3. ref_markersNext: The "next" frame of the reference markers from 
%           which to obtain the appropriate rotation and translation for the
%           created marker 
%
%   OUTPUTS: 
%       1. new_loc: the location of the created imaginary marker in the lab 
%           coordinate system
%
% Written by: CH, RvdL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Use the transrot function to calculate the rotation and translation of 
% reference markers from one position to the next in the lab coordinate system
[M_rot,d_trans] = transrot(ref_markers,ref_markersNext);

% Determine new location of 'imaginary marker' by transforming back to the 
% lab coordinate system
new_loc = (M_rot*ref_loc' + d_trans)';

end

