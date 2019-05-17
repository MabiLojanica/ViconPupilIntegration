function [trialRs] = resampleData(trial)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This function resamples the data and adjusts it starting position to match a 20fps timeline 
%   
%
%   INPUTS:
%       1.  trial
%
%   OUTPUTS:
%       1.  trialRs: Resampled data
%
%   Written by: DM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Resample Data
        % Change FPS from current to desired (20 fps)
        trialRs = resample(trial,trial(:,4),20);
        clear trial
                
        % Convert to cm scale
        trialRs(:,1:3) = trialRs(:,1:3) .*100;
        
        % See how different the intercept of time is compared to the
        % expected value at row 10 (0.2 seconds should have passed)
        sample = trialRs(10,4)-0.2;
        steps = round(sample*20,1);
        if steps < 0 
            disp('Kinect Timeline is quicker than csv')
        end
        newstep = 10 + steps;
        newstep = floor(newstep);
        
        % Shift the rows according to the steps specified
        trialRs(newstep:end+steps,:) = trialRs(10:end,:);
        
        % Append the empty values with the closest known value
        trialRs(1:newstep,:) = repmat(trialRs(newstep,:),newstep,1);



end
