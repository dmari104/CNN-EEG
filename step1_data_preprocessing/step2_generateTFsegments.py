
import os
import mne
import numpy as np
from PIL import Image
import matplotlib.pyplot as plt

import assets._segmentation as _segmentation
import assets._tf as _tf
import assets._artifactMapping as _artifactMapping

# Segmentation parameters
WINDOW_SIZE = 1.0
WINDOW_OVERLAP = 0.5
CUTOFF_LENGTH = 0.1

# Ordering of channels
CHANNEL_ORDER_STANDARD_10_20 = ['Fp1', 'Fp2', 'F3', 'F4', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2', 'F7', 'F8', 'T3',
                                'T4', 'T5', 'T6', 'Fz', 'Cz', 'Pz']

# Classes of segments
CLASSES = ['artifact', 'nonartifact']

# Preprocessed data folder
preprocessed_file_path = './data/preprocessed'
# Output file path for TF images
imageTF_file_path = './data/segmentedTF'

if not os.path.exists(imageTF_file_path):
    os.mkdir(imageTF_file_path)

if not os.path.exists(os.path.join(imageTF_file_path, CLASSES[0])):
    os.mkdir(os.path.join(imageTF_file_path, CLASSES[0]))
if not os.path.exists(os.path.join(imageTF_file_path, CLASSES[1])):
    os.mkdir(os.path.join(imageTF_file_path, CLASSES[1]))

# Get all files
allFiles = os.listdir(preprocessed_file_path)

# Count
allArtifacts = 0
allNonartifacts = 0

# Loop over files
for n, file in enumerate(allFiles):
    print('recording %s / %s' % (n + 1, len(allFiles)))
    fpath = os.path.join(preprocessed_file_path, file)
    # Load fif file
    preprocessed_recording = mne.io.read_raw_fif(fpath, preload=True)
    # Order channels
    preprocessed_recording.pick_channels(CHANNEL_ORDER_STANDARD_10_20, ordered=True)
    # Segment the recording
    print('Segmenting ...')
    segments = _segmentation.segmentRaw(preprocessed_recording, windowSize=WINDOW_SIZE, windowOverlap=WINDOW_OVERLAP)
    # Map segments on artifact annotation intervals
    print('Mapping segments on artifact annotation intervals ...')
    segments_mapped = _artifactMapping.map(preprocessed_recording, segments, WINDOW_SIZE, CUTOFF_LENGTH)
    # Update metadata
    segments_mapped._metadata = _segmentation._segment_metadata(preprocessed_recording,
                                                                segments_mapped.events, WINDOW_SIZE)

    # Get artifacts and nonartifacts
    artifacts = _artifactMapping.artifacts(segments_mapped)
    nonartifacts = _artifactMapping.nonartifacts(segments_mapped)
    artifacts.metadata.reset_index(inplace=True)
    nonartifacts.metadata.reset_index(inplace=True)

    # Generate TF images
    print('Generating TF images ...')
    intensityTF_artifacts = _tf.segmentTF(artifacts)
    intensityTF_nonartifacts = _tf.segmentTF(nonartifacts)

    # Save png images
    art_foutpath = os.path.join(imageTF_file_path, CLASSES[0])
    for i, artifact in enumerate(artifacts):
        start = round(artifacts.metadata['start'][i], 6)
        end = round(artifacts.metadata['end'][i], 6)
        fout = os.path.splitext(file)[0] + '_' + artifacts.metadata['true_label'][i] + '_' + \
               str(start) + '-' + str(end) + '.png'
        allArtifacts += 1
        dataTF = intensityTF_artifacts[i]
        img = Image.fromarray(np.uint8(dataTF))
        img.save(os.path.join(art_foutpath, fout), format="png")

    nonart_foutpath = os.path.join(imageTF_file_path, CLASSES[1])
    for i, artifact in enumerate(nonartifacts):
        start = round(nonartifacts.metadata['start'][i], 6)
        end = round(nonartifacts.metadata['end'][i], 6)
        fout = os.path.splitext(file)[0] + '_' + nonartifacts.metadata['true_label'][i] + '_' + \
               str(start) + '-' + str(end) + '.png'
        allNonartifacts += 1
        dataTF = intensityTF_nonartifacts[i]
        img = Image.fromarray(np.uint8(dataTF))
        img.save(os.path.join(nonart_foutpath, fout), format="png")

print('Total number of artifact segments: ', allArtifacts)
print('Total number of nonartifact segments: ', allNonartifacts)


#################
## Generate example figures

# recording_example_name = 'BAMBI.S501.yyyymmdd.ECRASD1_raw'
# outpath_example_artifacts = './data/examples/artifacts'
# outpath_example_nonartifacts = './data/examples/nonartifacts'

## Loop over files
# for n, file in enumerate(allFiles):
#     if recording_example_name in file:
#         fpath = os.path.join(preprocessed_file_path, file)
#         # Load fif file
#         preprocessed_recording = mne.io.read_raw_fif(fpath, preload=True)
#         # Order channels
#         preprocessed_recording.pick_channels(CHANNEL_ORDER_STANDARD_10_20, ordered=True)
#         # Segment the recording
#         print('Segmenting ...')
#         segments = _segmentation.segmentRaw(preprocessed_recording, windowSize=WINDOW_SIZE, windowOverlap=WINDOW_OVERLAP)
#         # Map segments on artifact annotation intervals
#         print('Mapping segments on artifact annotation intervals ...')
#         segments_mapped = _artifactMapping.map(preprocessed_recording, segments, WINDOW_SIZE, CUTOFF_LENGTH)
#         # Update metadata
#         segments_mapped._metadata = _segmentation._segment_metadata(preprocessed_recording,
#                                                                     segments_mapped.events, WINDOW_SIZE)
#
#         # Get artifacts and nonartifacts
#         artifacts = _artifactMapping.artifacts(segments_mapped)
#         nonartifacts = _artifactMapping.nonartifacts(segments_mapped)
#         artifacts.metadata.reset_index(inplace=True)
#         nonartifacts.metadata.reset_index(inplace=True)
#
#         fig=preprocessed_recording.plot(events=mne.pick_events(segments_mapped.events, exclude=2), start=94, duration=10,
#                                     scalings='auto', event_color={-1: "red", 1: "blue"}, show=True, bad_color='k',
#                                     clipping=2.5)
#         plt.savefig("501sbambi_94s.svg")
#         plt.show()
#
#         segments_mapped.plot(events=mne.pick_events(segments_mapped.events, exclude=2),
#                              event_id=segments_mapped.event_id, event_color={-1: "red", 1: "blue"}, n_channels=19, n_epochs=10,
#                              scalings='auto')
#         print(segments_mapped.event_id)
#         plt.savefig("5sec_segments_sbambi501.svg")
#         plt.show()
#
#         # Generate TF images
#         print('Generating TF images ...')
#         intensityTF_artifacts = _tf.segmentTF(artifacts)
#         intensityTF_nonartifacts = _tf.segmentTF(nonartifacts)
#
#         ###########################################################################
#         for i, artifact in enumerate(artifacts):
#             start = round(artifacts.metadata['start'][i], 6)
#             end = round(artifacts.metadata['end'][i], 6)
#             for j, channel in enumerate(CHANNEL_ORDER_STANDARD_10_20):
#                 fout = os.path.splitext(file)[0] + '_' + artifacts.metadata['true_label'][i] + '_' + \
#                        str(start) + '-' + str(end) + '_' + channel + '_' + '.png'
#                 dataTF = intensityTF_artifacts[i][j]
#                 img = Image.fromarray(np.uint8(dataTF))
#                 img.save(os.path.join(outpath_example_artifacts, fout), format="png")
#
#         for i, nonartifact in enumerate(nonartifacts):
#             start = round(nonartifacts.metadata['start'][i], 6)
#             end = round(nonartifacts.metadata['end'][i], 6)
#             for j, channel in enumerate(CHANNEL_ORDER_STANDARD_10_20):
#                 fout = os.path.splitext(file)[0] + '_' + nonartifacts.metadata['true_label'][i] + '_' + \
#                        str(start) + '-' + str(end) + '_' + channel + '_' + '.png'
#                 dataTF = intensityTF_nonartifacts[i][j]
#                 img = Image.fromarray(np.uint8(dataTF))
#                 img.save(os.path.join(outpath_example_nonartifacts, fout), format="png")
