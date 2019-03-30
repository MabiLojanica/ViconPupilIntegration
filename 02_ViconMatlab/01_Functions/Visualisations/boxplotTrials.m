function [q] = boxplotTrials(CellData, MedianTrials)
% Initialize a figure with all the angle distributions
q = figure;

for b = 1:size(CellData,1)
    % Create sublpot for each trial
    subplot(1,size(CellData,1),b)
    a = CellData{b,:};
    q = boxplot(a);
    q = title(MedianTrials(1,b));
end

saveas(q,'99_Plots/boxplot.png')
end

