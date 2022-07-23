import os
import numpy as np
import torch
import math
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

global device
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(device)

FP_THRESHOLD = 0.65
FN_THRESHOLD = 0.40

class MathTextSciFormatter(mticker.Formatter):
    def __init__(self, fmt="%1.2e"):
        self.fmt = fmt
    def __call__(self, x, pos=None):
        s = self.fmt % x
        decimal_point = '.'
        positive_sign = '+'
        tup = s.split('e')
        significand = tup[0].rstrip(decimal_point)
        sign = tup[1][0].replace(positive_sign, '')
        exponent = tup[1][1:].lstrip('0')
        if exponent:
            exponent = '10^{%s%s}' % (sign, exponent)
        if significand and exponent:
            s =  r'%s{\times}%s' % (significand, exponent)
        else:
            s =  r'%s%s' % (significand, exponent)
        return "${}$".format(s)


def total_stats(confusion_matrix, true_classes, artifact_probabilities):
    total_stats = {'total_arts': confusion_matrix[-2], 'total_clean': confusion_matrix[-1],
               'TP': confusion_matrix[0], 'FP': confusion_matrix[1], 'TN': confusion_matrix[2],
               'FN': confusion_matrix[3], 'true_classes': true_classes, 'art_probs': artifact_probabilities}
    return total_stats


# Scores: True positive rate (Recall -> TP / P), True negative rate (Specificity -> TN / N),
# False positive rate (FP / N), balaned accuracy (bACC -> (TPR + TNR) / 2), precision (TP / (TP + FP))
# F beta, accuracy
def print_stats(total_stats):
    beta = 2

    try:
        TPR = total_stats['TP'] / (total_stats['TP'] + total_stats['FN'])
    except ZeroDivisionError:
        TPR = math.nan
    try:
        FPR = total_stats['FP'] / (total_stats['FP'] + total_stats['TN'])
    except ZeroDivisionError:
        FPR = math.nan
    try:
        TNR = total_stats['TN'] / (total_stats['TN'] + total_stats['FP'])
    except ZeroDivisionError:
        TNR = math.nan
    try:
        Precision = total_stats['TP'] / (total_stats['TP'] + total_stats['FP'])
    except ZeroDivisionError:
        Precision = math.nan

    bACC = 0
    if not math.isnan(TPR) and not math.isnan(TNR):
        bACC = (TPR + TNR) / 2

    Fbeta = (1 + beta ** 2) * ((Precision * TPR) / (((beta ** 2) * Precision) + TPR))

    ACC = (total_stats['TP'] + total_stats['TN']) / (total_stats['total_arts'] + total_stats['total_clean'])

    print('total positives = %d ' % total_stats['total_arts'])
    print('total negatives = %d ' % total_stats['total_clean'])
    print('TP = %d; FP = %d; TN = %d; FN = %d' % (total_stats['TP'], total_stats['FP'], total_stats['TN'],
                                                  total_stats['FN']))
    print('TPR (true positive rate -> TP / total positives) = %f ' % TPR)
    print('TNR (true negative rate -> TN / total negatives) = %f ' % TNR)
    print('ACC (accuracy -> (TP + TN) / total) = %f ' % ACC)
    print('bACC (balanced accuracy) = %f ' % bACC)
    print('Precision = %f ' % Precision)
    print('F%d = %f ' % (beta, Fbeta))
    print('\n')


def plot_probability(artifact_segments, clean_segments, outpath, name=""):
    #     min_value = np.min([np.min(artifact_segments), np.min(clean_segments)])
    #     max_value = np.max([np.max(artifact_segments), np.max(clean_segments)])
    #     xticks = np.linspace(min_value, max_value, 6)
    colors = ['tab:blue', 'tab:red']
    plt.style.use('seaborn-deep')
    fig = plt.figure(figsize=(10, 7), facecolor='w', edgecolor='k')
    ax1 = fig.add_subplot()
    den, bins, _ = ax1.hist(artifact_segments, bins=30, density=False, alpha=0.9, lw=0.6,
                            color=colors[1], edgecolor="k", label='artifacts', range=(0, 1))
    d, bb, _ = ax1.hist(clean_segments, bins=30, alpha=0.7, lw=0.6, density=False, color=colors[0],
                        edgecolor="k", label='non-artifacts', range=(0, 1))
    ax1.legend(loc='best', prop={"size": 12}, frameon=False)
    if 'fn' in name:
        plt.axvline(x=0.4, color='k', label='false negative threshold')
    elif 'fp' in name:
        plt.axvline(x=0.65, color='k', label='false positive threshold')
    ax1.set_ylabel('Count', fontsize=12)
    ax1.set_xlabel('Probability to be artifact', fontsize=12)
    ax1.spines['right'].set_visible(False)
    ax1.spines['top'].set_visible(False)

    fig.subplots_adjust(right=0.7)
    fig.subplots_adjust(bottom=0.2)
    fig.subplots_adjust(top=0.8)
    #     plt.xticks(xticks)
    max_value = np.max([np.max(den), np.max(d)])
    yticks = np.linspace(0, max_value, 6)
    plt.yticks(yticks)
    plt.ticklabel_format(axis="y", style="scientific", scilimits=(3, 3))
    plt.gca().yaxis.set_major_formatter(MathTextSciFormatter("%1.1e"))

    fig.savefig(os.path.join(outpath, name + "probability_distribution.svg"), dpi=2000)

    plt.show()
    plt.close()

# Path to TF segments
data_path = '/Users/marinadiachenko/Documents/Projects/DL-EEG/CNN/DataPrep/data/segmentedTF'
# Output path
fout_path = './data/segments_to_review'
if not os.path.exists(fout_path):
    os.mkdir(fout_path)

# Classes of segments
CLASSES = ['artifact', 'nonartifact']
if not os.path.exists(os.path.join(fout_path, CLASSES[0])):
    os.mkdir(os.path.join(fout_path, CLASSES[0]))
if not os.path.exists(os.path.join(fout_path, CLASSES[1])):
    os.mkdir(os.path.join(fout_path, CLASSES[1]))

# Final model path
final_model_path = '../../final_models'

# Load model
model_data = torch.load(os.path.join(final_model_path, 'final_CNN.pth.tar'), map_location=torch.device('cpu'))

""" Final model fit to the training data"""
# Prediction probabilities of the two classes
probabilities = model_data['train_probabilities'].cpu().numpy()
# Prediction probabilities of artifacts
artifact_probabilities = [p[0] for p in probabilities]
# True labels
true_classes = model_data['train_true_classes'].view(1,-1)[0].cpu().numpy()
# Paths of training examples
image_paths = model_data['image_paths']
# Confusion matrix
confusion_matrix = model_data['train_confusion_matrix']  # (TP, FP, TN, FN, P, N)

# Identifier of EEG segment -> (recording name, sample positions, class label)
EEGsegments = [s.split('/')[-1] for s in image_paths]
# Unique recordings
recordings = np.unique(np.array([r.split('_')[0] for r in EEGsegments]))
stat_recordings = {}
for rec in recordings:
    if rec not in stat_recordings:
        stat_recordings[rec] = {}

print('Number of recordings in the train data = {}'.format(len(recordings)))

# Total stats into dict
model_total_stats = total_stats(confusion_matrix, true_classes, artifact_probabilities)
# Print performance stats
print('\t\t***** Total statistics: Final model fit to the training data *****')
print('\n')
print_stats(model_total_stats)

# Get artifact probabilities for true clean and artifact EEG segments
clean_segments = [prob for seg, prob, true in zip(EEGsegments, artifact_probabilities, true_classes) if true == 1]
artifact_segments = [prob for seg, prob, true in zip(EEGsegments, artifact_probabilities, true_classes) if true == 0]
print('# of clean segments = %d' % len(clean_segments))
print('# of artifact segments = %d' % len(artifact_segments))


# Most confident FP and FN predictions in the training data fit
# Prediction probabilities of artifacts
artifact_probabilities = [p[0] for p in probabilities]

# Epoch table (start, end, recording, prediction, true label, true class)
epochs_sbambi = [[float(segment.split('_')[-1].split('.png')[0].split('-')[0]),
                  float(segment.split('_')[-1].split('.png')[0].split('-')[1]),
                  segment.split('_')[0], prob, segment.split('_')[2], trueclass]
                 for segment, prob, trueclass in zip(EEGsegments, artifact_probabilities, true_classes)
                 if "SPACE" in segment or "BAMBI" in segment]
epochsAll = epochs_sbambi
print('# of all segments: ', len(epochsAll))
epoch_dict = {}
for i, epoch in enumerate(epochsAll):
    if epoch[2] not in epoch_dict:
        epoch_dict[epoch[2]] = [[epoch[0], epoch[1], epoch[2], epoch[3], epoch[4], epoch[5]]]
    else:
        epoch_dict[epoch[2]].append([epoch[0], epoch[1], epoch[2], epoch[3], epoch[4], epoch[5]])

# sort segments (ascending order)
for recording, values in epoch_dict.items():
    epoch_dict[recording] = sorted(values)

# add index
for values in epoch_dict.values():
    n_epochs = range(1, len(values)+1)
    i = 0
    for value in values:
        value.insert(0, n_epochs[i])
        i += 1

recordings = list(epoch_dict.keys())
rec = recordings[0]

"""Selection of false positive segments + adjacent segments in time"""

column_names = ['index', 'start', 'end', 'filename', 'probability', 'true_label', 'true_class']
fp_list = []
for recording, values in epoch_dict.items():
    for value in values:
        # if confident prediction of artifact, but true class is nonartifact (=1)
        if value[4] >= FP_THRESHOLD and value[6] == 1:
            # add 1 previous segment
            if value[0] != 1:
                ind = value[0]-1
                for value_back in values:
                    if value_back[0] == ind:
                        fp_list.append(value_back)
            # add current segment
            fp_list.append(value)
            # add 1 next segment
            if value[0] != len(values):
                ind = value[0]+1
                for value_forward in values:
                    if value_forward[0] == ind:
                        fp_list.append(value_forward)

# data table with confident FP segments +/- next/previous segment
df_fp = pd.DataFrame(fp_list, columns=column_names)
df_fp['predicted_class'] = 1
df_fp['predicted_class'] = np.where(df_fp['probability'] > 0.5, 0, df_fp['predicted_class'])
# drop duplicates
df_fp.drop_duplicates(inplace=True)
df_fp.reset_index(inplace=True, drop=True)
print("Number of false positive segments + adjacent = {}".format(df_fp.shape[0]))

# save table
if not os.path.exists(os.path.join(fout_path, 'fp_segments.csv')):
    df_fp.to_csv(os.path.join(fout_path,'fp_segments.csv'), index=False)

# get paths to the selected segments
fp_img_list = list(np.unique(['_'.join([img_info[3], 'raw', img_info[5], '.'.join(['-'.join([str(img_info[1]), str(img_info[2])]), 'png'])])
               for img_info in fp_list]))

# copy data - uncomment
# for img in fp_img_list:
#     fin = os.path.join(data_path, img.split('_')[2], img)
#     if not os.path.exists(os.path.join(fout_path, img.split('_')[2], img)):
#         fout = os.path.join(fout_path, img.split('_')[2], img)
#         shutil.copy(fin, fout)


"""Selection of false negative segments + adjacent segments in time"""
column_names = ['index', 'start', 'end', 'filename', 'probability', 'true_label', 'true_class']
fn_list = []
for recording, values in epoch_dict.items():
    for value in values:
        # if confident prediction of nonartifact, but true class is artifact (=0)
        if value[4] <= FN_THRESHOLD and value[6] == 0:
            # add 1 previous segment
            if value[0] != 1:
                ind = value[0]-1
                for value_back in values:
                    if value_back[0] == ind:
                        fn_list.append(value_back)

            # add current segment
            fn_list.append(value)
            # add 1 next segment
            if value[0] != len(values):
                ind = value[0]+1
                for value_forward in values:
                    if value_forward[0] == ind:
                        fn_list.append(value_forward)

# data table with confident FN segments +/- next/previous segment for context
df_fn = pd.DataFrame(fn_list, columns=column_names)
df_fn['predicted_class'] = 1
df_fn['predicted_class'] = np.where(df_fn['probability'] > 0.5, 0, df_fn['predicted_class'])

df_fn.drop_duplicates(inplace=True)
df_fn.reset_index(inplace=True, drop=True)
print("Number of false negative segments + adjacent segments = {}".format(df_fn.shape[0]))

if not os.path.exists(os.path.join(fout_path, 'fn_segments.csv')):
    df_fn.to_csv(os.path.join(fout_path, 'fn_segments.csv'), index=False)

fn_img_list = list(np.unique(['_'.join([img_info[3], 'raw', img_info[5], '.'.join(['-'.join([str(img_info[1]), str(img_info[2])]), 'png'])])
               for img_info in fn_list]))

print("# of selected FN segments + adjacent = ", len(fn_img_list))
print("# of selected FP segments + adjacent = ", len(fp_img_list))

all_imgs = fp_img_list + fn_img_list
print("# of all unique selected segments = ", len(np.unique(all_imgs)))

# copy data - uncomment
# for img in fn_img_list:
#     fin = os.path.join(data_path, img.split('_')[2], img)
#     if not os.path.exists(os.path.join(fout_path, img.split('_')[2], img)):
#         fout = os.path.join(fout_path, img.split('_')[2], img)
#         shutil.copy(fin, fout)


"""Plot probability distributions"""
fns = [[val1, val2] for val1, val2 in zip(df_fn['true_class'], df_fn['probability'])]
fps = [[val1, val2] for val1, val2 in zip(df_fp['true_class'], df_fp['probability'])]

#### Uncomment
# all = fns + fps
# artifacts = [val[1] for val in all if val[0] == 0]
# nonartifacts = [val[1] for val in all if val[0] == 1]
# plot_probability(artifacts, nonartifacts, fout_path, 'all_segments_')
#
# arts_fn = [val[1] for val in fns if val[0] == 0]
# nonarts_fn = [val[1] for val in fns if val[0] == 1]
# plot_probability(arts_fn, nonarts_fn, fout_path, 'fn_segments_')
#
# arts_fp = [val[1] for val in fps if val[0] == 0]
# nonarts_fp = [val[1] for val in fps if val[0] == 1]
# plot_probability(arts_fp, nonarts_fp, fout_path, 'fp_segments_')