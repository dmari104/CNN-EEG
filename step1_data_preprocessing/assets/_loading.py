
import numpy as np
import mat73
from scipy.io import loadmat
import mne


def _load_mat(fpath):
    data_dict = {}
    try:
        data_dict = mat73.loadmat(fpath)
    except TypeError:
        pass
    try:
        data_dict = loadmat(fpath)
    except NotImplementedError:
        pass
    return data_dict


def _parse(fpath):
    """Extract all the information from the mat file and create mne Info instance using mne.create_info."""

    data_dict = _load_mat(fpath)
    info_dict = _load_mat(fpath.split('.mat')[0] + '_info.mat')

    data = np.array(data_dict['eeg_data'])
    channels = list(np.reshape(np.array(info_dict['chanlocs']['labels']), -1))
    mne_info = mne.create_info(ch_names=channels, ch_types=['eeg'] * len(channels), sfreq=info_dict['sfreq'])
    mne_info['subject_info'] = {'his_id': str(int(info_dict['subjectID'])), 'condition': info_dict['conditionID']}

    if len(info_dict['bad_channels']) == len(channels):
        bad_channels = [int(bad) for bad in info_dict['bad_channels']]
    else:
        bad_channels = []

    if bad_channels:
        bad_channels = [ch for i, ch in enumerate(channels) if bad_channels[i] == 1]

    mne_rawArray = mne.io.RawArray(data=data, info=mne_info, first_samp=0, verbose=False)
    mne_rawArray.info['bads'] = bad_channels
    mne_rawArray._data = mne_rawArray.get_data() * 1e-6

    if len(np.array(info_dict['annotations']).shape) == 1:
        info_dict['annotations'] = np.reshape(np.array(info_dict['annotations']), (-1, 2)).tolist()

    mne_annotations = mne.Annotations([onset[0] / info_dict['sfreq'] for onset in info_dict['annotations']],
                                      [(onset[1] - onset[0]) / info_dict['sfreq'] for onset in
                                       info_dict['annotations']],
                                      description=["artifact"] * len(info_dict['annotations']))

    mne_rawArray.set_annotations(mne_annotations, emit_warning=True)
    mne_rawArray._filenames = [fpath, fpath.split('.mat')[0] + '_info.mat']
    pos = [[float(x), float(y), float(z)] for x, y, z in zip(info_dict['chanlocs']['X'],
                                                             info_dict['chanlocs']['Y'],
                                                             info_dict['chanlocs']['Z'])]
    dig_ch_pos = dict(zip(channels, pos))
    montage = mne.channels.make_dig_montage(ch_pos=dig_ch_pos)
    mne_rawArray.set_montage(montage)

    return mne_rawArray


def load(fpath):
    return _parse(fpath)