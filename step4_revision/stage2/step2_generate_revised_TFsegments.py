import os
import numpy as np
import shutil
import pandas as pd

# Input folder path for all labeled TF images
imageTF_folder_path = '/Users/marinadiachenko/Documents/Projects/DL-EEG/CNN/DataPrep/data/segmentedTF'
# Input file path for label-revised dataframe
revised_df_path = './data/revised_df.csv'
drowsiness_df_path = './data/drowsiness_df.csv'
uncertain_df_path = './data/uncertain_df.csv'

# Output folder path for label-revised TF images
revised_imageTF_folder_path = './data/revised_segmentedTF'

# Classes of segments
CLASSES = ['artifact', 'nonartifact']

if not os.path.exists(revised_imageTF_folder_path):
    os.mkdir(revised_imageTF_folder_path)

if not os.path.exists(os.path.join(revised_imageTF_folder_path, CLASSES[0])):
    os.mkdir(os.path.join(revised_imageTF_folder_path, CLASSES[0]))
if not os.path.exists(os.path.join(revised_imageTF_folder_path, CLASSES[1])):
    os.mkdir(os.path.join(revised_imageTF_folder_path, CLASSES[1]))

# Get all images
allArtifacts = os.listdir(os.path.join(imageTF_folder_path, CLASSES[0]))
allNonartifacts = os.listdir(os.path.join(imageTF_folder_path, CLASSES[1]))
allFiles = allArtifacts + allNonartifacts

# Get label-revised df
revised_df = pd.read_csv(revised_df_path)
df_drowsiness = pd.read_csv(drowsiness_df_path)
df_uncertain = pd.read_csv(uncertain_df_path)

df_drowsiness.reset_index(inplace=True)
df_drowsiness = df_drowsiness.set_index('id')

df_uncertain.reset_index(inplace=True)
df_uncertain = df_uncertain.set_index('id')

idx_exclude = np.where((revised_df['revised_class'] != 0) & (revised_df['revised_class'] != 1))[0]
revised_df.drop(idx_exclude, inplace=True)
revised_df.reset_index(inplace=True)
revised_df = revised_df.set_index('id')

print(11, len(np.where((revised_df['revised_class'] == revised_df['true_class']))[0]))
print(22, len(np.where((revised_df['revised_class'] != revised_df['true_class']))[0]))

print('# Revised = ', revised_df.shape[0])
print('# Uncertain = ', df_uncertain.shape[0])
print('# Drowsiness = ', df_drowsiness.shape[0])

revised_segments = revised_df.index.tolist()
revised_segments = [segment + '.png' for segment in revised_segments]
revised_classes = revised_df['revised_class'].tolist()
revised_labels = ['artifact' if class_number == 0 else 'nonartifact' for class_number in revised_classes]

original_classes = revised_df['true_class'].tolist()
original_labels = revised_df['true_label'].tolist()

drowsiness_segments = df_drowsiness.index.tolist()
drowsiness_segments = [segment + '.png' for segment in drowsiness_segments]

n_unchanged = 0
n_changed = 0
dr_n = 0
for i, image in enumerate(allFiles):
    fin = os.path.join(imageTF_folder_path, image.split('_')[2], image)
    print('Job for segment %d/%d' % (i, len(allFiles)))
    if image in drowsiness_segments:
        dr_n += 1
        continue

    if image in revised_segments:
        idx = revised_segments.index(image)
        class_number = revised_classes[idx]
        label = revised_labels[idx]
        original_label = original_labels[idx]

        filename_out = '_'.join(image.split('_')[0:2]) + '_' + label + '_' + image.split('_')[-1]
        fout = os.path.join(revised_imageTF_folder_path, label, filename_out)

        if label != original_label:
            n_changed += 1
        else:
            n_unchanged += 1

    else:
        filename_out = image
        label = image.split('_')[2]
        fout = os.path.join(revised_imageTF_folder_path, label, filename_out)

    # Copy
    if not os.path.exists(fout):
        shutil.copy(fin, fout)

print("# segments that changed label = ", n_changed)
print("# segments that didn't change label = ", n_unchanged)
print("# drowsiness labels = ", dr_n)