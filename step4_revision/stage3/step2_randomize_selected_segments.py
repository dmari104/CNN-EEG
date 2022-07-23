import os
import numpy as np
import shutil

# Input file path for all labeled TF segments
imageTF_file_path = '/Users/marinadiachenko/Documents/Projects/DL-EEG/CNN/DataPrep/data/segmentedTF'
# Input file path for selected for revision TF segments
selected_imageTF_file_path = '../stage1/data'
# Output file path for label-randomized selected for revision TF segments
randomized_imageTF_file_path = './data/random_selected_segments'

# Classes of segments
CLASSES = ['artifact', 'nonartifact']

if not os.path.exists(randomized_imageTF_file_path):
    os.mkdir(randomized_imageTF_file_path)

if not os.path.exists(os.path.join(randomized_imageTF_file_path, CLASSES[0])):
    os.mkdir(os.path.join(randomized_imageTF_file_path, CLASSES[0]))
if not os.path.exists(os.path.join(randomized_imageTF_file_path, CLASSES[1])):
    os.mkdir(os.path.join(randomized_imageTF_file_path, CLASSES[1]))

# Get all segments
allArtifacts = os.listdir(os.path.join(imageTF_file_path, CLASSES[0]))
allNonartifacts = os.listdir(os.path.join(imageTF_file_path, CLASSES[1]))
allFiles = allArtifacts + allNonartifacts

# Get falsely-predicted selected segments
false_positives = os.listdir(os.path.join(selected_imageTF_file_path, CLASSES[0]))
false_negatives = os.listdir(os.path.join(selected_imageTF_file_path, CLASSES[1]))
false_images = false_positives + false_negatives

p_arts = np.round(len(allArtifacts) / len(allFiles), 2)
p_nonarts = np.round(len(allNonartifacts) / len(allFiles), 2)

# Shuffle images
np.random.seed(7)
np.random.shuffle(false_images)

# Generate random labels
np.random.seed(10)
draws = np.random.choice(CLASSES, size=len(false_images))

# Save to new folder
for img, label in zip(false_images, draws):
    filename_out = '_'.join(img.split('_')[0:2]) + '_' + label + '_' + img.split('_')[-1]
    fin = os.path.join(selected_imageTF_file_path, img.split('_')[2], img)
    fout = os.path.join(randomized_imageTF_file_path, label, filename_out)
    if not os.path.exists(fout):
        shutil.copy(fin, fout)

# Save the rest of segments with their original labels
for img in allFiles:
    fin = os.path.join(imageTF_file_path, img.split('_')[2], img)
    if all(false_img!=img for false_img in false_images):
        fout = os.path.join(randomized_imageTF_file_path, img.split('_')[2], img)
        if not os.path.exists(fout):
            shutil.copy(fin, fout)
