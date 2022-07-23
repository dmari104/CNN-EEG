function EEG = sh_prepEEG(Data, filename, chanlocs, fs)
    % Get Ns
    nChannels = size(Data, 1);
    nSamples = size(Data, 2);
    
    % Create an EEG empty set
    EEG = eeg_emptyset();
    EEG.setname = filename;
    EEG.filename = filename;
    EEG.nbchan = nChannels;
    EEG.trials = 1;
    EEG.pnts = nSamples;
    EEG.srate = fs;
    EEG.xmin = 0;
    EEG.xmax = nSamples/EEG.srate;
    EEG.times = 1/EEG.srate:1/EEG.srate:EEG.xmax;
    EEG.data = Data;
    EEG.chanlocs = chanlocs;
end