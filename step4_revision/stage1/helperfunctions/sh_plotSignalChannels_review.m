function patchHandles = sh_plotSignalChannels_review(data, srate, chanlocs, verticalScale, badEpochs, badEpochs1, badEpochs2, recording)
    patchHandles = nan(1, size(badEpochs, 2));
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
        
        subplot(12, 1, 1:12);
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
        
        
        judgements = {'Remove', 'Keep', 'Dunno', 'Drowsiness'};
        colors = {'r', 'g', 'y', [0.5 0.5 0.5]};
        faces = [0.25, 0.1, 0.4, 0.4];
        
        yLimits = ylim();
        yRange = yLimits(2)-yLimits(1);
        y1 = yLimits(1)+0.2*yRange;
        y2 = yLimits(1)+0.4*yRange;
        
        if ~isnan(badEpochs1(eIdx))
            patchHandles(eIdx) = patch([eIdx-1, eIdx, eIdx, eIdx-1], [yLimits(1), yLimits(1), y1, y1], colors{badEpochs1(eIdx)+1}, 'FaceAlpha', faces(badEpochs1(eIdx)+1));
        end
        
        if ~isnan(badEpochs2(eIdx))
            patch([eIdx-1, eIdx, eIdx, eIdx-1], [y1, y1, y2, y2], colors{badEpochs2(eIdx)+1}, 'FaceAlpha', faces(badEpochs2(eIdx)+1));
        end
        
        if badEpochs(eIdx) == 0
            patchHandles(eIdx) = patch([eIdx-1, eIdx, eIdx, eIdx-1], [y2, y2, yLimits(2), yLimits(2)], 'r', 'FaceAlpha', 0.25);
        elseif badEpochs(eIdx) == 3
            patchHandles(eIdx) = patch([eIdx-1, eIdx, eIdx, eIdx-1], [yLimits(1), yLimits(1), yLimits(2), yLimits(2)], [0.5 0.5 0.5], 'FaceAlpha', 0.4);
        elseif badEpochs(eIdx) == 1
            patchHandles(eIdx) = patch([eIdx-1, eIdx, eIdx, eIdx-1], [y2, y2, yLimits(2), yLimits(2)], 'g', 'FaceAlpha', 0.1);
        elseif badEpochs(eIdx) == 2
            patchHandles(eIdx) = patch([eIdx-1, eIdx, eIdx, eIdx-1], [y2, y2, yLimits(2), yLimits(2)], 'y', 'FaceAlpha', 0.4);
        else
            patchHandles(eIdx) = NaN;
        end
    end

    % Plot the vertical lines
    for eIdx = 1 : nEpochs
        subplot(12, 1, 1:12)
        yLimits = ylim();
        line([eIdx, eIdx], [yLimits(1), yLimits(2)], 'Color', 'k');
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