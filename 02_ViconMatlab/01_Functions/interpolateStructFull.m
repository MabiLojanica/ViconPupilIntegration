function [ViconPointStruct] = interpolateStructFull(ViconPointStruct)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
% Access all the markers as a list

fields = fieldnames(ViconPointStruct);

for i = 1:numel(fields)
    
    
    %% Set all unknown to NAN
    ViconPointStruct.(fields{i})(ViconPointStruct.(fields{i}) == 0) = NaN;
    
    %% Set the first frame to a known value to prevent Runger phenomenon
    ind_start = find(~isnan(ViconPointStruct.(fields{i})(:,1)),1,'first');
    % get this first known frame and set it equal to the first 
    ViconPointStruct.(fields{i})(1,:) = ViconPointStruct.(fields{i})(ind_start,:);
    % Same procedure for the last
    ind_end = find(~isnan(ViconPointStruct.(fields{i})(:,1)),1,'last');
    ViconPointStruct.(fields{i})(1,:) = ViconPointStruct.(fields{i})(ind_end,:);
    
    % Cycle through each dimension (x,y,z)
    for d = 1:3
        ViconPointStruct.(fields{i})(:,d) = naninterp(ViconPointStruct.(fields{i})(:,d));
    end
    
    
end


end

