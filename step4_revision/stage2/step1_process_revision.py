
import numpy as np
import pandas as pd
import torch
import scipy.io


global device
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(device)

threshold_fp = 0.65
threshold_fn = 0.4

# I/O

fp_segment_path = './data/segments_to_review/df_fp_segments.txt'
revised_fp_segment_path1 = './data/reviewed/judgedEpochs_final_1_reviewer2.mat'
revised_fp_segment_path2 = './data/reviewed/judgedEpochs_final_1_reviewer1.mat'

fn_segment_path = './data/segments_to_review/df_fn_segments.txt'
revised_fn_segment_path1 = './data/reviewed/judgedEpochs_final_2_reviewer2.mat'
revised_fn_segment_path2 = './data/reviewed/judgedEpochs_final_2_reviewer1.mat'

final_revised_path = './data/revised_df.csv'
drowsiness_revised_path = './data/drowsiness_df.csv'
uncertain_revised_path = './data/uncertain_df.csv'


def revised_fp_df(path_segments, path_revised, threshold):

    segments = pd.read_csv(path_segments)
    revised_labels = scipy.io.loadmat(path_revised)['keepEpochs'][0]
    segments['revised_class'] = revised_labels

    # Filter based on threshold
    if threshold != 0.0:
        segments = segments.iloc[np.where((segments['true_class'] != segments['predicted_class']) &
                                          (segments['probability'] >= threshold))[0]]
        segments.reset_index(drop=True, inplace=True)
    else:
        segments = segments

    return segments


def revised_fn_df(path_segments, path_revised, threshold):
    segments = pd.read_csv(path_segments)
    revised_labels = scipy.io.loadmat(path_revised)['keepEpochs'][0]
    segments['revised_class'] = revised_labels

    # Filter based on threshold
    if threshold != 0:
        segments = segments.iloc[np.where((segments['true_class'] != segments['predicted_class']) &
                                          (segments['probability'] <= threshold))[0]]
        segments.reset_index(drop=True, inplace=True)
    else:
        segments = segments

    return segments


def get_final_revised(fp_df_1, fp_df_2, fn_df_1, fn_df_2):
    # Join FPs and FNs of each rater, accordingly
    df_1 = pd.concat([fp_df_1, fn_df_1])
    df_1 = df_1[~df_1.index.duplicated(keep='first')]
    df_2 = pd.concat([fp_df_2, fn_df_2])
    df_2 = df_2[~df_2.index.duplicated(keep='first')]

    df_fp_fn_1 = df_1.loc[:, ['revised_class', 'true_class', 'true_label', 'predicted_class']]
    df_fp_fn_2 = df_2.loc[:, ['revised_class', 'true_class', 'true_label', 'predicted_class']]
    df_fp_fn = df_fp_fn_1.join(df_fp_fn_2, lsuffix='_1', rsuffix='_2')

    idx_agreement = np.where((df_fp_fn['revised_class_1'] == df_fp_fn['revised_class_2']) & (df_fp_fn['revised_class_1'] != 2) & (df_fp_fn['revised_class_1'] != 3))[0]
    idx_drowsiness = np.where((df_fp_fn['revised_class_1'] == 3) | (df_fp_fn['revised_class_2'] == 3))[0]
    idx_uncertain = np.where((df_fp_fn['revised_class_1'] == 2) | (df_fp_fn['revised_class_2'] == 2))[0]
    idx_disagreement = np.where((df_fp_fn['revised_class_1'] != df_fp_fn['revised_class_2'])
                                & (df_fp_fn['revised_class_1'] != 2) & (df_fp_fn['revised_class_1'] != 3) &
                                (df_fp_fn['revised_class_2'] != 2) & (df_fp_fn['revised_class_2'] != 3))[0]

    df_disagreement = df_fp_fn.iloc[idx_disagreement, :]
    df_disagreement = df_disagreement.loc[:, ['revised_class_1', 'true_class_1', 'true_label_1', 'predicted_class_1']]
    df_disagreement.rename(columns={'revised_class_1': 'revised_class', 'true_class_1': 'true_class',
                                 'true_label_1': 'true_label', 'predicted_class_1': 'predicted_class'}, inplace=True)
    df_disagreement['revised_class'] = df_disagreement['true_class']

    df_uncertain = df_fp_fn.iloc[idx_uncertain, :]
    df_uncertain = df_uncertain.loc[:, ['revised_class_1', 'true_class_1', 'true_label_1', 'predicted_class_1']]
    df_uncertain.rename(columns={'revised_class_1': 'revised_class', 'true_class_1': 'true_class',
                                     'true_label_1': 'true_label', 'predicted_class_1': 'predicted_class'}, inplace=True)
    df_uncertain['revised_class'] = np.ones(df_uncertain.shape[0], dtype=int) * int(2)

    df_drowsiness = df_fp_fn.iloc[idx_drowsiness, :]
    df_drowsiness = df_drowsiness.loc[:, ['revised_class_1', 'true_class_1', 'true_label_1', 'predicted_class_1']]
    df_drowsiness.rename(columns={'revised_class_1': 'revised_class', 'true_class_1': 'true_class',
                                    'true_label_1': 'true_label', 'predicted_class_1': 'predicted_class'}, inplace=True)
    df_drowsiness['revised_class'] = np.ones(df_drowsiness.shape[0], dtype=int)*int(3)

    df_agreement = df_fp_fn.iloc[idx_agreement, :]
    df_agreement = df_agreement.loc[:, ['revised_class_1', 'true_class_1', 'true_label_1', 'predicted_class_1']]
    df_agreement.rename(columns={'revised_class_1': 'revised_class', 'true_class_1': 'true_class',
                                    'true_label_1': 'true_label', 'predicted_class_1': 'predicted_class'}, inplace=True)

    return df_agreement, df_drowsiness, df_uncertain, df_disagreement


fp_df_1 = revised_fp_df(fp_segment_path, revised_fp_segment_path1, 0)
fp_df_2 = revised_fp_df(fp_segment_path, revised_fp_segment_path2, 0)
fn_df_1 = revised_fn_df(fn_segment_path, revised_fn_segment_path1, 0)
fn_df_2 = revised_fn_df(fn_segment_path, revised_fn_segment_path2, 0)

fp_df_1['id'] = fp_df_1['filename'].map(str) + '_raw_' + fp_df_1['true_label'].map(str) + '_' + \
                    fp_df_1['start_time'].map(str) + '-' + fp_df_1['end_time'].map("{:.6f}".format)
fp_df_1 = fp_df_1.set_index('id')
fp_df_2['id'] = fp_df_2['filename'].map(str) + '_raw_' + fp_df_2['true_label'].map(str) + '_' + \
                    fp_df_2['start_time'].map(str) + '-' + fp_df_2['end_time'].map("{:.6f}".format)
fp_df_2 = fp_df_2.set_index('id')

fn_df_1['id'] = fn_df_1['filename'].map(str) + '_raw_' + fn_df_1['true_label'].map(str) + '_' + \
                fn_df_1['start_time'].map(str) + '-' + fn_df_1['end_time'].map("{:.6f}".format)
fn_df_1 = fn_df_1.set_index('id')

fn_df_2['id'] = fn_df_2['filename'].map(str) + '_raw_' + fn_df_2['true_label'].map(str) + '_' + \
                fn_df_2['start_time'].map(str) + '-' + fn_df_2['end_time'].map("{:.6f}".format)
fn_df_2 = fn_df_2.set_index('id')

df_1 = pd.concat([fp_df_1, fn_df_1])
df_1 = df_1[~df_1.index.duplicated(keep='first')]
df_2 = pd.concat([fp_df_2, fn_df_2])
df_2 = df_2[~df_2.index.duplicated(keep='first')]

df_fp_fn_1 = df_1.copy()
df_fp_fn_2 = df_2.copy()

df_1_ = df_1.loc[:, ['revised_class', 'true_class', 'true_label', 'predicted_class']]
df_2_ = df_2.loc[:, ['revised_class', 'true_class', 'true_label', 'predicted_class']]
df_revised_all = df_1_.join(df_2_, lsuffix='_1', rsuffix='_2')

final_df_revised, df_drowsiness, df_fp_uncertain, df_disagreement = get_final_revised(fp_df_1, fp_df_2, fn_df_1, fn_df_2)
print("Total revised = ", final_df_revised.shape[0])
print("Total drowsiness = ", df_drowsiness.shape[0])
print("Total uncertain = ", df_fp_uncertain.shape[0])
print("Total disagreement = ", df_disagreement.shape[0])

final_df_revised.to_csv(final_revised_path, index=True)
df_drowsiness.to_csv(drowsiness_revised_path, index=True)
df_fp_uncertain.to_csv(uncertain_revised_path, index=True)