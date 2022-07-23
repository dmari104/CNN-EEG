
import os
import numpy as np
import shutil

# Input file path for labeled TF segments
imageTF_file_path = '/Users/marinadiachenko/Documents/Projects/DL-EEG/CNN/DataPrep/data/segmentedTF'
# Output file path for label-randomized TF segments
randomized_imageTF_file_path = './data/random_allsegments'

# Classes of segments
CLASSES = ['artifact', 'nonartifact']

if not os.path.exists(randomized_imageTF_file_path):
    os.mkdir(randomized_imageTF_file_path)

if not os.path.exists(os.path.join(randomized_imageTF_file_path, CLASSES[0])):
    os.mkdir(os.path.join(randomized_imageTF_file_path, CLASSES[0]))
if not os.path.exists(os.path.join(randomized_imageTF_file_path, CLASSES[1])):
    os.mkdir(os.path.join(randomized_imageTF_file_path, CLASSES[1]))

# Get all images
allArtifacts = os.listdir(os.path.join(imageTF_file_path, CLASSES[0]))
allNonartifacts = os.listdir(os.path.join(imageTF_file_path, CLASSES[1]))
allFiles = allArtifacts + allNonartifacts

# Get probalitites of each class based on the number of examples in each class
p_arts = np.round(len(allArtifacts) / len(allFiles), 2)
p_nonarts = np.round(len(allNonartifacts) / len(allFiles), 2)

# Shuffle images
np.random.seed(7)
np.random.shuffle(allFiles)

# Generate random labels
np.random.seed(10)  # 10, 5, 9
# draws = np.random.choice(CLASSES, size=len(allFiles))
draws = np.random.choice(CLASSES, size=len(allFiles), p=[p_arts, p_nonarts])

# Save
for img, label in zip(allFiles, draws):
    filename_out = '_'.join(img.split('_')[0:2]) + '_' + label + '_' + img.split('_')[-1]
    fin = os.path.join(imageTF_file_path, img.split('_')[2], img)
    fout = os.path.join(randomized_imageTF_file_path, label, filename_out)
    if not os.path.exists(fout):
        shutil.copy(fin, fout)





