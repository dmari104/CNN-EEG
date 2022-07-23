addpath(genpath('helperfunctions'))

% Specify input and output folder
infolder = './data';
folder_output = './data/reviewed';
if ~exist(folder_output, 'dir')
    mkdir(folder_output);
end

load(fullfile(infolder, 'fp_segments.mat'));
keepEpochs_1 = prediction;
keepEpochs_2 = true_class;
max_n = 5;

% Load reviewed epochs
if exist(fullfile(folder_output, 'judgedEpochs_final_1.mat'), 'file')
    load(fullfile(folder_output, 'judgedEpochs_final_1.mat'), 'keepEpochs', 'eIdx');
    keepEpochs = keepEpochs;
    eIdx = eIdx;
else
    keepEpochs = nan(1, size(keepEpochs_2, 2));
    eIdx = 1;
    keepEpochs(find(keepEpochs_1==0&keepEpochs_2==0)) = 0;
    keepEpochs(find(keepEpochs_1==1&keepEpochs_2==1)) = 1;
    keepEpochs(find(keepEpochs_1==3&keepEpochs_2==3)) = 3;
    keepEpochs(find(keepEpochs_1==2|keepEpochs_2==2)) = 2;
    keepEpochs(find((keepEpochs_1==1&keepEpochs_2==0) | ...
        (keepEpochs_1==0&keepEpochs_2==1))) = 2;
    keepEpochs(find((keepEpochs_1==1&keepEpochs_2==3) | ...
        (keepEpochs_1==3&keepEpochs_2==1))) = 2;
    keepEpochs(find((keepEpochs_1==3&keepEpochs_2==0) | ...
        (keepEpochs_1==0&keepEpochs_2==3))) = 2;
end

epoch_groups = consecutive_epoch_ids(1:n(1), :);
e_end = n(1);
e_start = e_end + 1;
for j = 2:size(n, 2)
    e_end = e_end + n(j);
    epochs = consecutive_epoch_ids(e_start:e_end, :);
    tmp = ones(n(j), 2)*epoch_groups(end, 2);
    tmp = tmp + epochs;
    epoch_groups = [epoch_groups; tmp];
    e_start = e_end + 1;
end

epoch_group_diff = epoch_groups(:, 2) - epoch_groups(:, 1);
inds = find(epoch_group_diff>=10);
p_inds = inds - 1;
n_inds = inds + 1;
if p_inds(end)<size(epoch_groups, 1)
    p_inds(end+1) = size(epoch_groups, 1);
end

epochs = epoch_groups(1:p_inds(1), :);
for ind=1:size(inds, 1)
    t = floor((epoch_groups(inds(ind), 2) - epoch_groups(inds(ind), 1) + 1 ) / max_n);
    tmp_1 = epoch_groups(inds(ind), 1);
    tmp_2 = epoch_groups(inds(ind), 1) + 4;
    epochs = [epochs; tmp_1, tmp_2];
    for j=2:t
        tmp_1 = tmp_2 + 1;
        if j==t
            tmp_2 = epoch_groups(inds(ind), 2);
        else
            tmp_2 = tmp_2 + 5;
        end
        epochs = [epochs; tmp_1, tmp_2];
    end
    tmp = epoch_groups(n_inds(ind):p_inds(ind+1), :);
    epochs = [epochs; tmp];
end

% Color coding for keeping epochs
%   0, Red: Both reviewers said: remove
%   1, Green: Both reviewers said keep
%   2, Yellow: Reviewers disagreed (or were uncertain)

figHandle = figure();
set(figHandle, 'Units', 'Inches');
set(figHandle, 'Position', [3, 7, 18, 10]);
set(figHandle, 'Color', 'w');

judgementDefault = 1;
while eIdx <= size(epochs, 1)  
    epochs_current = epochs(eIdx, 1):epochs(eIdx, 2);
    verticalScale = 100;
    
    keepEpochs_sel_1 = keepEpochs_1(epochs_current);
    keepEpochs_sel_2 = keepEpochs_2(epochs_current);
    data_pop = data(epochs_current);
    srate_pop = srate(epochs_current);
    recordings_pop = recording(epochs_current);
    keepEpochs_sel = keepEpochs(epochs_current);
    
    patchHandles = sh_plotSignalChannels_review(data_pop, srate_pop, chanlocs, verticalScale, keepEpochs_sel, keepEpochs_sel_1, keepEpochs_sel_2, recordings_pop);
    
    str_title = ['Epoch ', num2str(epochs_current(1)), ' to ', num2str(epochs_current(end))];
    title(str_title, 'FontSize', 16);
    
    w = waitforbuttonpress;
    key = get(gcf,'currentcharacter');
    keys = cellstr(string(1:size(keepEpochs_sel, 2)));
    if size(keepEpochs_sel, 2) == 10
        keys(end) = {'0'};
    end

    while ~strcmp(key, '.') && ~strcmp(key, 'p') && ~strcmp(key, ',')
        if find(ismember(key, keys))
            yLimits = ylim();
            key = str2num(key);
            if key == 0; key = 10; end
            if keepEpochs_sel(key) == 0
                keepEpochs_sel(key) = 3;
                set(patchHandles(key), 'FaceColor', [0.5 0.5 0.5], 'FaceAlpha', 0.4); % drowsiness
            elseif keepEpochs_sel(key) == 3
                keepEpochs_sel(key) = 2;
                set(patchHandles(key), 'FaceColor', 'y', 'FaceAlpha', 0.4); % doubt
            elseif keepEpochs_sel(key) == 2
                keepEpochs_sel(key) = 1;
                set(patchHandles(key), 'FaceColor', 'g', 'FaceAlpha', 0.1); % clean
            elseif keepEpochs_sel(key) == 1
                keepEpochs_sel(key) = 0;
                set(patchHandles(key), 'FaceColor', 'r', 'FaceAlpha', 0.25); % artifact
            end
        elseif strcmp(key, 'i')
            % Invert judgment
            if judgementDefault == 0
                judgementDefault = 1;
                keepEpochs_sel = ones(1, 10);
                set(patchHandles(1:10), 'FaceColor', 'g', 'FaceAlpha', 0.1);
            else
                judgementDefault = 0;
                keepEpochs_sel = zeros(1, 10);
                set(patchHandles(1:10), 'FaceColor', 'r', 'FaceAlpha', 0.25);
            end
        else
            disp('Illegal key press! Press z to remove or m to keep.');
        end

        w = waitforbuttonpress;
        key = get(gcf,'currentcharacter');
    end
    
    keepEpochs(epochs_current) = keepEpochs_sel;
        
    if strcmp(key, '.')
        if eIdx + 1 > size(epochs, 1)
            eIdx = eIdx;
        else
            eIdx =  eIdx+1;
        end
    elseif strcmp(key, ',')
        eIdx = eIdx-1;
        if eIdx < 1
            eIdx = 1;
        end
    elseif strcmp(key, 'p')
        keepEpochs(epochs_current) = keepEpochs_sel;
        % Pause and save
        close(figHandle);
        break;
    end
    
    cla
end

% Save
save(fullfile(folder_output, 'judgedEpochs_final_1.mat'), 'keepEpochs', 'eIdx');