function [patchHandles] = sh_plotSignalChannels(data, srate, chanlocs, verticalScale, badEpochs1, badEpochs2, recording)
%     figHandle = figure();
%     set(figHandle, 'Color', 'w');
    hold on;
    
    nEpochs = length(data);
    for eIdx = 1 : nEpochs
%         subplot(10, 10, eIdx)
%         hold on;
%         mnData = nanmean(data{eIdx}, 2);
%         sh_topoplot(mnData, chanlocs);
%         caxis([min(mnData), max(mnData)]);
%         colormap(redblue(50));
%         
%         subplot(8, 1, 1:2)
%         hold on;
        timeVec = (1/srate{eIdx}+eIdx-1:1/srate{eIdx}:eIdx);
        dataVec = data{eIdx};
        
%         plot(timeVec, dataVec);
%         set(gca, 'xticklabel', []);
        
        subplot(8, 1, 1:8);
        hold on;
        channels = size(dataVec, 1):-1:1;
        
        % Create distance between signals for plotting
        if ~verticalScale==0
            temp = single(verticalScale : verticalScale : length(channels) * verticalScale);
            dataVec(channels, :) = dataVec(channels, :) + repmat(temp, size(dataVec, 2), 1)';
        end
        nicecolors
        plot(timeVec, dataVec(channels, :)', 'Color', blue_dark);
        set(gca,'YTick', verticalScale:verticalScale:length(channels)*verticalScale, 'YTickLabel', fliplr({chanlocs.labels}));
        set(gca, 'xtick', [0.5:1:9.5]);
        set(gca, 'xticklabel', [1:9, 0]);
        
        if eIdx > 1 && recording(eIdx) > recording(eIdx-1)
            yLimits = ylim();
            text(eIdx-1, yLimits(2), num2str(recording(eIdx)));
        end
    end

    % Plot the vertical lines
    for eIdx = 1 : nEpochs
%         subplot(10, 10, eIdx)
%         yLimits = ylim();
%         line([eIdx, eIdx], [yLimits(1), yLimits(2)], 'Color', 'k');
        
%         subplot(8, 1, 1:2)
%         yLimits = ylim();
%         line([eIdx, eIdx], [yLimits(1), yLimits(2)], 'Color', 'k');
        
        subplot(8, 1, 1:8)
        yLimits = ylim();
        line([eIdx, eIdx], [yLimits(1), yLimits(2)], 'Color', 'k');
        
        
            
        if ~isempty(find(ismember(find(badEpochs1==0), eIdx)))
            patchHandles(eIdx) = patch([eIdx-1, eIdx, eIdx, eIdx-1], [yLimits(1), yLimits(1), yLimits(2), yLimits(2)], 'r', 'FaceAlpha', 0.25);
        elseif find(ismember(find(badEpochs1==3), eIdx))
            patchHandles(eIdx) = patch([eIdx-1, eIdx, eIdx, eIdx-1], [yLimits(1), yLimits(1), yLimits(2), yLimits(2)], [0.5 0.5 0.5], 'FaceAlpha', 0.4);
        elseif find(ismember(find(badEpochs1==2), eIdx))
            patchHandles(eIdx) = patch([eIdx-1, eIdx, eIdx, eIdx-1], [yLimits(1), yLimits(1), yLimits(2), yLimits(2)], 'y', 'FaceAlpha', 0.4);
        else 
            patchHandles(eIdx) = patch([eIdx-1, eIdx, eIdx, eIdx-1], [yLimits(1), yLimits(1), yLimits(2), yLimits(2)], 'g', 'FaceAlpha', 0.1);
        end
    end

% 
%     
%     plot(timeWindow, data');
%     set(gca, 'xticklabel', []);
% %     ylim([-150, 150]);
%     set(gca, 'XLim', [0, 1]);
%     
%     subplot(8, 1, 3:8);
% 
%     channels = size(data, 1):-1:1;
%     
%     % Create distance between signals for plotting
%     if ~verticalScale==0
%         temp = single(verticalScale : verticalScale : length(channels) * verticalScale);
%         data(channels, :) = data(channels, :) + repmat(temp, size(data, 2), 1)';
%     end
%     
%     % Plot the signal
%     plot(timeWindow, data(channels, :)');
% %     set(gca,'YTick', verticalScale:verticalScale:length(channels)*verticalScale, 'YTickLabel', fliplr({chanlocs.labels}));
%     set(gca, 'YLim', [0, verticalScale*(length(channels)+1)]);
%     set(gca, 'XLim', [0, 1]);
    xlabel('Time', 'FontSize', 16);
    
%     set(figHandle, 'Units', 'Inches');
%     set(figHandle, 'Position', [3, 7, 18, 10]);
end