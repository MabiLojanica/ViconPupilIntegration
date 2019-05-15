function [ViconPointStruct] = interpolateStruct(ViconPointStruct, NaNTreshold)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
% Access all the markers as a list

fields = fieldnames(ViconPointStruct);

for i = 1:numel(fields)
    
    
    
    
    %% NaN threshold
    % Get the absolute number of NaNs in the point
    check = sum(sum(ViconPointStruct.(fields{i}) == 0));
    size = 3*length(ViconPointStruct.(fields{i}));
    % If the percentage of missing is below threshold, interpolate. else,
    % dont
    
    % Set all 0 values to NaN
    ViconPointStruct.(fields{i})(ViconPointStruct.(fields{i}) == 0) = NaN;
    if (check / size) < (NaNTreshold /100)
        
        
        % Cycle through each dimension (x,y,z)
        for d = 1:3
            ViconPointStruct.(fields{i})(:,d) = naninterp(ViconPointStruct.(fields{i})(:,d));
        end
    end
    
end


end

