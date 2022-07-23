addpath(genpath('helperfunctions'))
addpath(genpath('Software'))

% Specify input and output folder
infolder = '/Users/marinadiachenko/Documents/data/SPACE_BAMBI';
folder_output = './data';

allRecordings = list_recordings(infolder);

% ['index', 'start', 'end', 'filename', 'probability', 'true_label', 'true_class', 'predicted_class']
fp = readtable('./data/segments_to_review/fp_segments.csv', 'HeaderLines',1, 'ReadRowNames', 0);

recs = convertCharsToStrings(fp.Var4);
recordings = unique(recs);
epochs = [fp.Var1, fp.Var2, fp.Var3];
true_classes = fp.Var7;
fp_model_predictions = fp.Var8;

df = table;
for r=1:size(recordings)
    inds = find(recs==recordings(r));
    tmp = table(fp.Var2(inds), fp.Var3(inds), convertCharsToStrings(fp.Var4(inds)), ...
        fp.Var5(inds), convertCharsToStrings(fp.Var6(inds)), fp.Var7(inds), fp.Var8(inds));
    df = [df;tmp];
end
df.Properties.VariableNames = {'start_time', 'end_time', 'filename', 'probability', 'true_label', 'true_class', 'predicted_class'};
writetable(df, './data/df_fp_segments.txt');

consecutive_epoch_ids = [];
n = [];
data = {};
srate = [];
epoch = [];
recording = [];
true_class = [];
prediction = [];
selected_ch = {'Fp1'; 'F7'; 'T7'; 'P7'; 'F3'; 'C3'; 'P3'; 'O1'; 'Fp2'; ...
    'F8'; 'T8'; 'P8'; 'F4'; 'C4'; 'P4'; 'O2'; 'Fz'; 'Cz'; 'Pz'};

for rIdx = 1 : length(recordings)
    fprintf('Recording number %d/%d\n', rIdx, size(recordings, 1))
    rec = recordings{rIdx};
    idx = find(contains(allRecordings, rec));
    inds_epochs = find(recs==rec);
    selected_epochs = epochs(inds_epochs, :);
    selected_true_classes = true_classes(inds_epochs, :);
    selected_predictions = fp_model_predictions(inds_epochs, :);
    
    % Load
    RawSignal = load(allRecordings{idx});
    RawSignal = RawSignal.RawSignal;
    Info = load(strrep(allRecordings{idx}, '.mat', '_info.mat'));
    RawSignalInfo = Info.RawSignalInfo;
    
    % 1. Convert to EEGLAB
    EEG = nbt_NBTtoEEG(RawSignal, RawSignalInfo, '', []);

    % 2. Bandpass-filter 0.5-45 Hz
    EEG_filt = pop_eegfiltnew(EEG, 0.5, 45);

    % 3. Interpolate bad channel using spherical spline interpolation
    EEG_filt = pop_interp(EEG_filt, find(RawSignalInfo.badChannels), 'spherical');

    % 4. Re-reference to average reference
    EEG_filt = pop_reref(EEG_filt, []);
    
    % all channels
    all_ch = struct2table(EEG_filt.chanlocs);
    all_ch = all_ch.labels;
    % Find selected channels
    channels = [];
    for ch = 1:size(selected_ch, 1)
        ind = find(strcmp(all_ch, selected_ch{ch})==1);
        channels = [channels; ind];
    end
    
    % Keep selected channels
    EEG_filt = pop_select(EEG_filt, 'channel', channels);
    
    selected_epochs = [selected_epochs(:, 1), int64(selected_epochs(:, [2,3])*EEG_filt.srate)];
    selected_epochs(selected_epochs(:,2)==0, 2) = 1;
    selected_epochs(selected_epochs(:,2)==1, 3) = selected_epochs(selected_epochs(:,2)==1, 3) + 1;
    
    % Determine indices of consecutive epochs
    lagged_index = zeros(size(selected_epochs, 1), 1);
    lagged_index(2:end) = selected_epochs(1:end-1, 1);
    lagged_index(1) = selected_epochs(1, 1);
    cmp = [selected_epochs(:, 1), lagged_index(:, 1)];
    diff_cmp = cmp(:, 1) - cmp(:, 2);
    idxs = find(diff_cmp>1);
    idxs = [1; idxs];
    idxs(:, 2) = ones(size(idxs, 1), 1)*size(selected_epochs, 1);
    idxs(1:end-1, 2) = idxs(2:end, 1) - 1;
    consecutive_epoch_ids = [consecutive_epoch_ids; idxs];
    n(end+1) = size(idxs, 1);

	for eIdx = 1 : size(selected_epochs, 1)
        recording(end+1) = rIdx;
        epoch(end+1) = selected_epochs(eIdx, 1);
        data{end+1} = single(EEG_filt.data(:, selected_epochs(eIdx, 2):selected_epochs(eIdx, 3)));
        srate{end+1} = EEG_filt.srate;
        true_class(end+1) = selected_true_classes(eIdx);
        prediction(end+1) = selected_predictions(eIdx);
    end
    
end

% Save
chanlocs = EEG_filt.chanlocs;
save(fullfile(folder_output, 'fp_segments.mat'), 'recordings', 'recording', ...
    'epoch', 'srate', 'data', 'chanlocs', 'true_class', 'prediction', ...
    'consecutive_epoch_ids', 'n', '-v7.3');
