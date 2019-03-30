function [q] = boxplotTrials(CellData, MedianTrials,plotyesno,trialname,saveyesno,filetype)
% Initialize a figure with all the angle distributions

%       6. plotyesno: 1 to plot
%       7. trialname: char of the trial name for plotting and saving
%       8. saveyesno: 1 to save plot - Place file destination on line 96.
%       9. filetype: char of file type to be saved (ie. '.jpg' or '.fig').
%           Only necessary if saving (saveyesno == 1).

if plotyesno == 1
    
    q = figure;
    
    for b = 1:size(CellData,1)
        % Create sublpot for each trial
        subplot(1,size(CellData,1),b)
        a = CellData{b,:};
        q = boxplot(a);
        q = title(MedianTrials(1,b));
    end
    
%% In case saving is on
    if saveyesno == 1
        saveas(q,fullfile('99_Plots/', strcat(trialname, filetype)))
    end
end

end

