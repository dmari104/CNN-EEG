import os
import numpy as np
import assets._loading as _loading
import assets._preprocessing as _preprocessing
import mne

# Preprocessing parameters
FILTER_HP = 0.5
FILTER_LP = 45
REFERENCE = 'average'

# Standard 10-20 alphabetic channel names
STANDARD_10_20 = ['Fp1', 'F7', 'T3', 'T5', 'F3', 'C3', 'P3', 'O1', 'Fp2', 'F8', 'T4', 'T6', 'F4', 'C4',
                 'P4', 'O2', 'Fz', 'Cz', 'Pz']

# Biosemi64 standard 10-20 channel names
BIOSEMI64_10_20 = ['Fp1', 'F7', 'T7', 'P7', 'F3', 'C3', 'P3', 'O1', 'Fp2', 'F8', 'T8', 'P8', 'F4', 'C4',
                 'P4', 'O2', 'Fz', 'Cz', 'Pz']

EGI128_10_20 = ['E21', 'E33', 'E40', 'E51', 'E20', 'E36', 'E53', 'E74', 'E14', 'E122', 'E109', 'E97', 'E118',
                'E104', 'E86', 'E82', 'E11', 'E55', 'E62']

# Mapping of biosemi channels to standard alphabetic
MAPPING_BIOSEMI64_STANDARD_10_20 = dict(zip(BIOSEMI64_10_20, STANDARD_10_20))
MAPPING_EGI128_10_20_STANDARD_10_20 = dict(zip(BIOSEMI64_10_20, STANDARD_10_20))


def list_recordings(infolder):
    exclusions = ['analysis', 'info', 'biomarkerbase', 'asdvstdc', 'nbtelementbase', 'nbtstudy', 'bed']
    extensions = ['.mat']
    recordings = []
    # Get all recordings
    for root, dirs, files in os.walk(infolder):
        recordings += [os.path.join(root, file) for file in files]

    # Keep files with allowed extensions
    recordings = [rec for rec in recordings if any(extension in rec.lower() for extension in extensions)]
    # Exclude files containing exclusion words
    recordings = [rec for rec in recordings if all(exclusion not in rec.lower() for exclusion in exclusions)]
    return recordings

# Data folder path
raw_file_path = './data/raw'
# Output data path
preprocessed_file_path = './data/preprocessed'
# Get all files
allFiles = list_recordings(raw_file_path)

annotation_length_total = 0
recording_length_total = 0

# Preprocess recordings
for i, recording in enumerate(allFiles):
    print('recording %s / %s' % (i+1, len(allFiles)))
    outfpath = os.path.join(preprocessed_file_path,
                                       os.path.splitext(os.path.basename(recording))[0] + '_raw.fif')
    if not os.path.isfile(outfpath):
        # Load raw file
        raw = _loading.load(recording)
        length_artifacts = np.sum(raw.annotations.duration)
        annotation_length_total = annotation_length_total + length_artifacts
        recording_length_total = recording_length_total + len(raw.times)/raw.info['sfreq']
        # Band-pass filter
        print('Band-pass filtering ...')
        preprocessedRaw = _preprocessing.filter_fir(raw, hp=FILTER_HP, lp=FILTER_LP)
        # Interpolate bad channels
        print('Interpolating bad channels ...')
        preprocessedRaw = _preprocessing.interpolate_bads(preprocessedRaw)
        # Re-reference to common average
        print('Re-referencing to %s reference...' % REFERENCE)
        preprocessedRaw = _preprocessing.reref(preprocessedRaw, reference=REFERENCE)
        # Pick 19 channels
        print('Selecting %s channels ...' % str(len(BIOSEMI64_10_20)))
        print(BIOSEMI64_10_20)
        preprocessedRaw.pick_channels(BIOSEMI64_10_20, ordered=True)
        # Rename channels to standard 10-20 alphabetic
        print('Renaming to standard 10-20 alphabetic channels ...')
        print(STANDARD_10_20)
        mne.rename_channels(preprocessedRaw.info, MAPPING_BIOSEMI64_STANDARD_10_20)
        print(preprocessedRaw.info)
        # Save
        print('Saving preprocessed file ...')
        preprocessedRaw.save(outfpath)
    else:
        print('Preprocessed file already exists!')

print(annotation_length_total)
print(recording_length_total)