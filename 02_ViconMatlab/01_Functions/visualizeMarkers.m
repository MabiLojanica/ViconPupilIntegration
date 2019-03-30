function [h] = visualizeMarkers (ViconPointStruct, pointsInfo,fileLength,startingFrame,LeftHandVector,RightHandVector)
% visualizeMarkers
%   This script takes a vicon point struct and displays all markers in a 3d
%   plot. Works best for less than 10 markers. The animation can be stopped
%   by pressing 'escape' any time to return.

% Input:    ViconPointStruct: A Vicon .c3d read with btkGetPoints()
%           pointsInfo: Vicon metadata read also with btkGetPoints()
%           fileLength: Metadata acquired by btkGetLastFrame
%           startingFrame: The frame the visualisation starts from
% Output:   3d Scatterplot with drawnow

h = figure;

% Access all the markers as a list
fields = fieldnames(ViconPointStruct);


% Estimate frame per frame duration
delta = 1 / pointsInfo.frequency;
%% Estimate real time replay factor (try to replay data with 23 fps)
jumps = floor(pointsInfo.frequency / 23);

% Cycle through each frame
for k = startingFrame:jumps:fileLength
    % Cycle through all marker points in the list
    for i = 1:numel(fields)
        field = fields{i}; % Define actual field
        x = ViconPointStruct.(field)(k,1);
        y = ViconPointStruct.(field)(k,2);
        z = ViconPointStruct.(field)(k,3);
        % Scatterplot of the xyz position of the current marker
        h = scatter3(x,y,z,'filled','black');
        
        
    end
    
    %% Also plot the vector lines
    
    % Lineplots need vertical concatenations
    vVertLeft = [ViconPointStruct.HeadUke_c(k,:);ViconPointStruct.LeftHand_c(k,:)];
    vVertRight = [ViconPointStruct.HeadUke_c(k,:);ViconPointStruct.RightHand_c(k,:)];
    
    
    line(LeftHandVector(:,1), LeftHandVector(:,2), LeftHandVector(:,3))
    
    
    
    
    drawnow
    hold on
    pause(delta*jumps)
    
    %% Check if escape key has been pressed
    key = get(gcf,'CurrentKey');
    if(strcmp (key , 'escape'));
        return
    else
        key = [];
    end
    
    
    
end

end

