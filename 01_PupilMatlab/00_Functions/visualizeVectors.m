function [h] = visualizeVectors (array, frequency,fileLength,startingFrame,plotyesno)
% visualizeMarkers
%   This script takes a vicon point struct and displays all markers in a 3d
%   plot. Works best for less than 10 markers. The animation can be stopped
%   by pressing 'escape' any time to return.

% Input:    ViconPointStruct: A Vicon .c3d read with btkGetPoints()
%           pointsInfo: Vicon metadata read also with btkGetPoints()
%           fileLength: Metadata acquired by btkGetLastFrame
%           startingFrame: The frame the visualisation starts from
% Output:   3d Scatterplot with drawnow


if plotyesno == 1
    
    h = figure;
    
    % Estimate frame per frame duration
    delta = 1 / frequency;
    %% Estimate real time replay factor (try to replay data with 23 fps)
    jumps = floor(frequency / 23);
    
    % Cycle through each frame
    for k = startingFrame:jumps:fileLength
        % Cycle through all marker points in the list
        for i = 1:3
            x = array(k,1);
            y = array(k,2);
            z = array(k,3);
            % Scatterplot of the xyz position of the current marker
            h = scatter3(x,y,z,'filled','black');
        end
        
        title('NormalizedGazePoints')
        xlabel('X')
        ylabel('Y')
        zlabel('Z')
        
        % line(LeftHandVector(:,1), LeftHandVector(:,2), LeftHandVector(:,3))
        
        
        
        
        drawnow
        hold on
        %     pause(delta*jumps)
        
        %% Check if escape key has been pressed
        key = get(gcf,'CurrentKey');
        if(strcmp (key , 'escape'));
            return
        else
            key = [];
        end
        
    end
    
end

end

