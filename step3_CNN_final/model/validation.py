# -*- coding: utf-8 -*-

"""
    Description:
        Supporting module for the utility.py module from utils

        Contains functions to add noise to the images (not tested), calculate class weights in a data set, split data into
        train, validation, and test sets

    Note:
        Parts of code are taken from https://pytorch.org/docs/ or various Internet sources

"""

import math

import torch
import numpy as np
import random
from sklearn.model_selection import KFold
from utils import utility


def get_minorityIdx_train(dataset, train_idx, minority_ratio=1):
    # get all targets from the split
    train_targets = list(np.array(dataset.targets))
    minority_examplesIdx = np.array([idx for idx, target in enumerate(train_targets) if target == 0
                                     and idx in train_idx])
    size = int(len(minority_examplesIdx)*minority_ratio)
    replacement = False
    if minority_ratio <= 1:
        replacement = False
    elif minority_ratio > 1:
        replacement = True
    #samplesIdx = np.array(random.sample(list(minority_examplesIdx), size))
    samplesIdx = np.random.choice(minority_examplesIdx, size=size, replace=replacement)

    return samplesIdx


def split(dataset, train_test_split=0.8, val_train_split=0.2, shuffle=True): #train_test_split=0.8, val_train_split=0.1
    """ Function to split the dataset into train, validation, and test sets with unbalanced classes.
            Args:
                dataset (ImageFolder):
                train_test_split (float):
                val_train_split (float):
                shuffle (bool): whether to shuffle the data, True or False (default = True)
            Returns: indices of examples for the train, validation, and test sets
        """

    # get the number of examples for train and test based on test_train_split ratio
    dataset_size = len(dataset)
    indices = list(range(dataset_size))
    test_split = int(np.floor(train_test_split * dataset_size))

    # shuffle the data as a default
    #np.random.seed(utility.seed)
    if shuffle:
        np.random.shuffle(indices)
    # split the dataset into train and test (get corresponding indices)
    train_idx, test_idx = indices[:test_split], indices[test_split:]
    train_size = len(train_idx)

    # get the number of examples for validation set from the train set based on val_train_split ratio
    validation_split = int(np.floor((1 - val_train_split) * train_size))

    # split the train set into train and validation (get corresponding indices)
    train_idx, val_idx = train_idx[: validation_split], train_idx[validation_split:]

    return train_idx, val_idx, test_idx


def get_class_ids(dataset):
    # Get ids of all artifacts and non-artifacts
    class_ids = [[],[]]
    for i, image in enumerate(dataset.imgs):
        class_ids[image[1]].append(i)
    return class_ids


def weighted_split(class_ids, weights, train_test_split=0.8, val_train_split=0.2, permute=True):
    """ Function to split the dataset into train, validation, and test sets with balanced classes.
            Args:
                class_ids (array): IDs of examples for each class in the dataset
                weights (tensor): a tensor of weights for each example in the dataset
                                    (based on the number of examples in each class)
                train_test_split (float):
                val_train_split (float):
                shuffle (bool): whether to shuffle the data, True or False (default = True)
            Returns: indices of examples for the train, validation, and test sets
        """

    # total number of artifacts in the dataset
    num_arts = len(class_ids[0])
    # size of the new balanced dataset
    new_size = num_arts*2
    new_weights = weights.detach().clone()

    # keep all artifacts, balance with the same number of non-artifacts, and zero out the rest of non-artifacts
    random.seed(utility.seed)
    new_weights[class_ids[0]] = 1 # all artifact weights to 1
    new_weights[class_ids[1]] = 0 # all non-artifact weights to 0
    # select all artifacts
    selected_art_inds = torch.multinomial(new_weights, num_samples=int(num_arts), replacement=False)
    new_weights[class_ids[0]] = 0 # all artifact weights to 0
    new_weights[class_ids[1]] = 1 # all non-artifact weights to 1
    # select the same number of non-artifacts randomly
    selected_non_art_inds = torch.multinomial(new_weights, num_samples=int(num_arts), replacement=False)

    # set all non-artifact weights to 0
    new_weights[class_ids[1]] = 0
    # set all artifact weights to 1
    new_weights[selected_art_inds] = 1
    # set all selected non-artifact weights to 1
    new_weights[selected_non_art_inds] = 1

    # subset a new balanced dataset
    inds = torch.multinomial(new_weights, num_samples=int(new_size), replacement=False)

    # shuffle the data
    #np.random.seed(utility.seed)
    if permute:
       inds = np.random.permutation(inds)

    test_split = int(np.floor(train_test_split * new_size))

    # split the dataset into train and test (get corresponding indices)
    train_idx, test_idx = inds[:test_split], inds[test_split:]
    train_size = len(train_idx)

    # get the number of examples for validation set from the train set based on val_train_split ratio
    validation_split = int(np.floor((1 - val_train_split) * train_size))

    # split the train set into train and validation (get corresponding indices)
    train_idx, val_idx = train_idx[: validation_split], train_idx[validation_split:]

    return train_idx, val_idx, test_idx


def loo_test_val_ids(dataset, test_ratio=0.1, val_ratio=0.1):
    """ Support function to get indices for EEG segments of the chosen subject which will
        be hold out for the test set """

    imgs = [image[0].split("/")[-1] for image in dataset.imgs]
    subjects1 = ['.'.join([image[0].split("/")[-1].split(".")[0], image[0].split("/")[-1].split(".")[1]])
                 for image in dataset.imgs if 'SPACE' in image[0].split("/")[-1]]
    subjects2 = ['.'.join([image[0].split("/")[-1].split(".")[0], image[0].split("/")[-1].split(".")[1]])
                 for image in dataset.imgs if 'BAMBI' in image[0].split("/")[-1]]
    subjects3 = [image[0].split("/")[-1].split("_")[0] for image in dataset.imgs
                 if len(image[0].split("/")[-1].split('_')) > 3]
    subjects = subjects1 + subjects2 + subjects3
    # get image filenames and subject IDs for each TF EEG segment/example
    # for i, image in enumerate(dataset.imgs):
    #     subjects.append(image[0].split("/")[-1].split(".")[1])
    #     imgs.append(image[0].split("/")[-1])
    # initiate an array of weights for each segment/example with zeros
    weights = np.array([0]*len(imgs))
    weights = torch.DoubleTensor(weights)
    # get unique subject IDs
    unique_ids = np.unique(subjects)
    length = len(unique_ids)
    ratio_total = test_ratio + val_ratio
    subj_to_sample = math.ceil(ratio_total*length)
    n_splits = math.ceil(length/subj_to_sample)
    # get the split
    kf = KFold(n_splits=n_splits, shuffle=True, random_state=7)
    test_val_idx = [tval_idx for train_idx, tval_idx in kf.split(unique_ids)]
    test_subj = math.ceil(test_ratio*length)
    random.seed(30)
    seeds = random.sample(range(1, 1000), utility.n_seeds)
    split_seed = seeds[utility.seed_idx]
    ind = [i for i, s in enumerate(seeds) if s == split_seed][0]
    tval_split = test_val_idx[ind]
    np.random.seed(7)
    np.random.shuffle(tval_split)
    test_inds, val_inds = tval_split[: test_subj], tval_split[test_subj:]

    # get subject ID strings
    test_subject_id_str = unique_ids[test_inds]
    val_subject_id_str = unique_ids[val_inds]
    print('seed idx', utility.seed_idx)
    print('seed', split_seed)
    print('test subjects', test_subject_id_str)
    print('val subjects', val_subject_id_str)
    print('total number of subject = ', length)
    print('number of test subjects = ', len(test_subject_id_str))
    print('number of val subjects = ', len(val_subject_id_str))
    # find all indices of the chosen subject in the imgs list
    test_subj_inds = []
    for s in range(0, len(test_subject_id_str)):
        test_subj_inds.extend([imgs.index(i) for i in imgs if 'SPACE' in i
                               and '.'.join([i.split(".")[0], i.split(".")[1]]) == test_subject_id_str[s]])
        test_subj_inds.extend([imgs.index(i) for i in imgs if 'BAMBI' in i
                               and '.'.join([i.split(".")[0], i.split(".")[1]]) == test_subject_id_str[s]])
        test_subj_inds.extend([imgs.index(i) for i in imgs if len(i.split("_")) > 3
                               and i.split("_")[0] == test_subject_id_str[s]])
    val_subj_inds = []
    for s in range(0, len(val_subject_id_str)):
        val_subj_inds.extend([imgs.index(i) for i in imgs if 'SPACE' in i
                               and '.'.join([i.split(".")[0], i.split(".")[1]]) == val_subject_id_str[s]])
        val_subj_inds.extend([imgs.index(i) for i in imgs if 'BAMBI' in i
                               and '.'.join([i.split(".")[0], i.split(".")[1]]) == val_subject_id_str[s]])
        val_subj_inds.extend([imgs.index(i) for i in imgs if len(i.split("_")) > 3
                               and i.split("_")[0] == val_subject_id_str[s]])
    # set weights for the EEG segments of that subject to 1
    weights[test_subj_inds] = 1

    return test_subj_inds, val_subj_inds


def loo_split(dataset, val_train_split=0.1, permute=True):
    """ Function to split the dataset into train, validation, and test sets based on leave-%subjects-out """

    dataset_size = len(dataset)
    indices = list(range(dataset_size))

    # test set indices - hold-out EEG segments indices of the selected subject + validation set indices
    test_idx, val_idx = loo_test_val_ids(dataset, val_ratio=val_train_split)
    # all other indices
    train_inds = [i for i in indices if i not in test_idx]
    train_idx = [i for i in train_inds if i not in val_idx]

    # shuffle the data as a default
    if permute:
        np.random.shuffle(train_idx)

    return train_idx, val_idx, test_idx


def calc_class_weight(targets, example_count):
    """ Support function to compute class weight per class """

    # calculate weight for each class as 1/[number of examples in a class]
    weight = 1. / example_count
    #weight = example_count.min() / example_count

    # assign class weight to each example
    class_weight = np.array([weight[t] for t in targets])
    class_weight = torch.from_numpy(class_weight)
    class_weight = class_weight.float().cuda()

    return class_weight


def get_class_weights(dataset, idx):
    """ Function to get class weight per class """

    # get all targets from the split
    train_targets = list(np.array(dataset.targets)[idx])
    # get class counts in the split
    class_example_count = np.array([len(np.where(train_targets == target)[0]) for target in list(set(train_targets))])
    # compute class weight as 1/[N,M] where N is the number of examples in class 1 and M in class 2
    class_weights = calc_class_weight(list(set(train_targets)), class_example_count)

    return class_weights


def get_class_counts(dataset, idx):
    """ Function to get the number of examples in each class """

    # get all targets from the split
    train_targets = list(np.array(dataset.targets)[idx])
    # compute class counts
    class_example_count = np.array([len(np.where(train_targets == target)[0]) for target in list(set(train_targets))])

    return class_example_count


def get_example_weights(images, nclasses):
    """ Function to calculate weights for each example in each class as the total number of examples divided by the
            number of examples in a class.
        Note: taken from Internet """

    # initiate count of examples per class
    count = [0] * nclasses
    for item in images:
        count[item[1]] += 1
    # initiate weight per class
    weight_per_class = [0.] * nclasses
    # total number of examples over classes
    N = float(sum(count))
    # calculate weight per class as N/[class count]
    for i in range(nclasses):
        weight_per_class[i] = N/float(count[i])
    # initiate example weights
    example_weights = [0] * len(images)
    # assing weights to each example based on class belonging
    for idx, val in enumerate(images):
        example_weights[idx] = weight_per_class[val[1]]

    return example_weights


# OLD function
def compute_class_weights(dataset1, dataset2, idx):

    # Get indices from idx of the split separately for dataset 1 and dataset 2
    idx1 = [x for x in idx if x < len(dataset1)]
    idx2 = [x - len(dataset1) for x in idx if x >= len(dataset1)]

    # Get all targets from the split
    train_targets = list(np.array(dataset1.targets)[idx1]) + list(np.array(dataset2.targets)[idx2])

    # Compute class weight as 1/[N,M] where N is the number of examples in class 1 and M in class 2
    class_example_count = np.array([len(np.where(train_targets == target)[0]) for target in list(set(train_targets))])
    class_weights = calc_class_weight(list(set(train_targets)), class_example_count)

    return class_weights