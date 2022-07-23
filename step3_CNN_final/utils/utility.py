#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
    Description:
    Parses arguments from the command line
    It contains functions to create a dataset of class ImageFolder (which inherits from DatasetFolder) and load the data
    using DataLoader with a sampler strategy

    Note: parts of code are taken from https://pytorch.org/docs/ or various Internet sources

"""

from __future__ import print_function
from argparse import ArgumentParser, RawTextHelpFormatter
from torch.utils.data import DataLoader, ConcatDataset, SubsetRandomSampler
from torchvision import datasets
from torchvision.transforms import transforms
from torch.utils.tensorboard import SummaryWriter

import sys
import os
import numpy as np
import random
import torch
import torch.nn as nn

# import local modules
from utils.reader import image_reader, ReshapeTransform, PaddingChannelsTransform
from model.cnn import ConvNet2D
from model.models import Model, model_summary
from model.validation import get_example_weights, weighted_split, split, \
    get_class_weights, get_class_counts, get_minorityIdx_train, get_class_ids, loo_split


# Device configuration
global device
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')


def parse_args():
    """ Parses inputs from command line and returns them as a Namespace object """

    parser = ArgumentParser(prog='python3 [script.py]', formatter_class=RawTextHelpFormatter, description=
        '  Perform CNN training for artifact detection in EEG data.\n\n'
        '  Example syntax:\n'
        '    python3 main.py ./data_path -o ./output -[options: -s, -c, -b, -e, -l, --scheduler]')

    # Positionals
    parser.add_argument('data', help='path to the dataset for training. '
                                     'Each child folder holds data for a specific artifact type')

    # Optionals
    parser.add_argument('-s', dest='sampler', type=str, default='RandomSubset',
                        help='sampler to sample the data: "WeightedRandomSubset" for balanced dataset;  '
                             '"RandomSubset" for unbalanced dataset; "Loo" for leave-20%-out subject-wise')
    parser.add_argument('-b', dest='batch_size', type=int, default=64, help='the number of examples per batch')
    parser.add_argument('-e', dest='epochs', type=int, default=70, help='number of epochs to train the network')
    parser.add_argument('-l', dest='lr', type=float, default=0.0001, help='learning rate')
    parser.add_argument('-n', dest='number_seeds', type=int, default=10, help='number of seeds')
    parser.add_argument('-i', dest='seed_idx', type=int, default=0, help='index for the seed')

    parser.add_argument('-o', dest='output', default='./results',
                        help='path to the directory where output files are saved\n '
                             '(directory will be made if it does not exist)')

    parser.add_argument('-r', dest='resume', action='store_true',
                        help='resume unfinished training')

    parser.add_argument('-f', dest='final', action='store_true',
                        help='train final CNN')

    return parser.parse_args()


class ImageFolderWithPaths(datasets.ImageFolder):
    """Custom dataset that includes image file paths. Extends
    torchvision.datasets.ImageFolder
    Note: borrowed from Internet
    """

    # override the __getitem__ method. this is the method that dataloader calls
    def __getitem__(self, index):
        # this is what ImageFolder normally returns
        original_tuple = super(ImageFolderWithPaths, self).__getitem__(index)
        # the image file path
        path = self.imgs[index][0]
        # make a new tuple that includes original and the path
        tuple_with_path = (original_tuple + (path,))
        return tuple_with_path


def get_image_tf(data_path, transform=transforms.ToTensor()):
    """Get data loader using PyTorch generic data loader ImageFolder
        Args:
            data_path (str): a path to a folder containing folders with 'artifact' and 'nonartifact' class images.
            transform (callable, optional): a function that takes in an example and returns a transformed version.
        Returns: ImageFolder data loader for the desired dataset with paths
    """
    dataset = ImageFolderWithPaths(root=data_path, loader=image_reader, transform=transform)

    return dataset


def load_image_tf(dataset, batch_size, output_path, sampler=None):
    """Load ImageFolder dataset using PyTorch generic data loaders
            Args:
                dataset (ConcatDataset or Dataset): a data loader from which to load the dataset.
                batch_size (int): the number of examples per batch to load.
                output_path (str): a path to store class labels with their corresponding binary assignment
                sampler(optional): defines the strategy to draw samples from the dataset.
            Returns:
        """
    if type(dataset).__name__ == 'ConcatDataset':
        classes = [cls for cls in dataset.datasets[0].class_to_idx.keys()]
        for cls, label in dataset.datasets[0].class_to_idx.items():
            classes[label] = cls
    else:
        classes = [cls for cls in dataset.class_to_idx.keys()]
        for cls, label in dataset.class_to_idx.items():
            classes[label] = cls
        # write binary label assignment to a file
        open(output_path + '/labels', 'w').write('\n'.join('%s %s' % (x[0], x[1])
                                                           for x in dataset.class_to_idx.items()))
    try:
        # load
        if sampler is not None:
            loader_data = DataLoader(dataset, batch_size=batch_size, sampler=sampler, num_workers=2, shuffle=False)
        else:
            loader_data = DataLoader(dataset, batch_size=batch_size, num_workers=2, shuffle=True)
    except AttributeError as e:
        print('Something went wrong. Check your input!')
        raise e

    return loader_data, classes


def parse_data(args=False, train=True):
    """Parse data"""

    '''Global variables'''
    global max_epochs
    global train_dir
    global test_dir
    global writer
    global classes
    global seed
    global resume
    global output_path
    global seed_idx
    global num_channels
    global n_seeds

    num_channels = 19
    new_num_channels = 19
    groups = 19
    padding = new_num_channels - num_channels

    '''Process arguments'''
    if not args: args = parse_args()
    # dataset path
    data_path = args.data
    # path to the output directory
    output_path = args.output
    # sampler strategy
    sampler_strategy = args.sampler
    if sampler_strategy not in ['WeightedRandomSubset', 'RandomSubset', 'Loo']:
        sys.exit('Sampler strategy [-s] argument error')
    # get batch size and max number of epochs
    batch_size = args.batch_size
    max_epochs = args.epochs
    # initial learning rate
    learning_rate = args.lr
    # number of seeds
    n_seeds = args.number_seeds
    # seed idx
    seed_idx = args.seed_idx
    if seed_idx not in list(range(n_seeds)):
        sys.exit('Seed index [-i] is out of bounds')
    # if training should be resumed from an epoch
    resume = args.resume
    # if want to train the final model
    final = args.final

    # seeds for splitting the data into train, test, and validation
    random.seed(30)
    seeds = random.sample(range(1, 1000), n_seeds)
    # choose a seed
    seed = seeds[seed_idx]
    # set the seed
    np.random.seed(seed)
    torch.manual_seed(seed)

    '''Prepare output folders'''
    if not final:
        '''Create folders for storing results'''
        if not os.path.exists(output_path):
            print('Creating directory for storing results: ' + output_path)
            os.makedirs(output_path)
        if not os.path.exists(os.path.join(output_path, 'train_validation')):
            os.makedirs(os.path.join(output_path, 'train_validation'))
        if not os.path.exists(os.path.join(output_path, 'test')):
            os.makedirs(os.path.join(output_path, 'test'))
    else:
        if not os.path.exists(output_path):
            print('Creating directory for storing results: ' + output_path)
            os.makedirs(output_path)
        if not os.path.exists(os.path.join(output_path, 'train_final')):
            os.makedirs(os.path.join(output_path, 'train_final'))

    # define paths to results
    train_dir = os.path.join(output_path, 'train_validation', 'seed_{}'.format(seed))
    test_dir = os.path.join(output_path, 'test', 'seed_{}'.format(seed))
    writer = SummaryWriter(os.path.join(output_path, 'runs/experiment_seed_{}'.format(seed)))

    if final:
        train_dir = os.path.join(output_path, 'train_final', 'seed_{}'.format(seed))

    '''Define hyperparameters and functions'''
    # number of convolutional layers
    n_conv = 3
    # model architecture
    net = ConvNet2D(num_classes=2, h=45, w=100, num_channels=new_num_channels, groups=groups).to(device)
    # optimizer ASGD
    optimizer = torch.optim.ASGD(net.parameters(), lr=learning_rate)

    '''Get data and class weights'''
    # define main data transform
    transform = transforms.Compose([transforms.ToTensor(), ReshapeTransform((num_channels,45,100)), PaddingChannelsTransform(padding)])  # convert to torch tensor and reshape
    # get dataset and weights per example based on class belonging
    dataset = get_image_tf(data_path, transform=transform)
    # get class ids
    class_ids = get_class_ids(dataset)
    # weights for each class example in the dataset: N_total/n_class
    weights = get_example_weights(dataset.imgs, len(dataset.classes))
    example_weights = torch.DoubleTensor(weights)

    '''Split data'''
    # get data indices for train, validation, and test splits
    train_idx, val_idx, test_idx = None, None, None
    # create unbalanced sets
    if sampler_strategy == "RandomSubset":
        train_idx, val_idx, test_idx = split(dataset)
    # create balanced sets
    elif sampler_strategy == "WeightedRandomSubset":
        train_idx, val_idx, test_idx = weighted_split(class_ids, example_weights)
    elif sampler_strategy == "Loo":
        train_idx, val_idx, test_idx = loo_split(dataset)
    # compute class weights in the train set
    class_weights = get_class_weights(dataset, train_idx)

    '''Define optimization criterion, data samplers'''
    # define loss function
    criterion = nn.CrossEntropyLoss(weight=class_weights)
    # define train, validation, and test samplers for the data loader
    train_sampler = SubsetRandomSampler(train_idx)
    val_sampler = SubsetRandomSampler(val_idx)
    test_sampler = SubsetRandomSampler(test_idx)

    # for the final model
    if final:
        print('******** Training final model')
        print('=' * 100)
        idx = np.array(range(len(dataset.targets)))
        class_weights = get_class_weights(dataset, idx)
        # define loss function
        criterion = nn.CrossEntropyLoss(weight=class_weights)
        print('=> Dataset counts [art, non-art]: ', get_class_counts(dataset, idx))
        print('=> Full dataset size: {}'.format(len(dataset)))

    # create Model instance
    network = Model(net=net, optimizer=optimizer, criterion=criterion)

    '''Print msg'''
    print('******** Hyperparameters')
    print('=' * 100)
    print('=> Number of convolutional layers = {}'.format(n_conv))
    print('=> Batch size = {}'.format(batch_size))
    print('=> Max number of epochs = {}'.format(max_epochs))
    print('=' * 100 + '\n')
    print('******** Sampling and number of instances in the data sets')
    print('=' * 100)
    print('=> {} sampling was used => class weights = '.format(sampler_strategy), class_weights)
    print('=> Train set [art, non-art]: ', get_class_counts(dataset, train_idx))
    print('=> Validation set [art, non-art]: ', get_class_counts(dataset, val_idx))
    print('=> Test set [art, non-art]: ', get_class_counts(dataset, test_idx))
    print('=' * 100 + '\n')
    print('******** Sizes of data sets')
    print('=' * 100)
    print('=> Full dataset size: {}'.format(len(dataset)))
    print("=> Train set size: {}".format(len(train_idx)))
    print("=> Validation set size: {}".format(len(val_idx)))
    print("=> Test set size: {}".format(len(test_idx)))
    print('=' * 100 + '\n')
    model_summary(network.net)
    print('\n')
    print("******** Job for seed {}".format(seed))
    print('=' * 100)
    print('Resume training {}'.format(resume))

    '''Load data'''
    # load sets of data
    train_data, classes = load_image_tf(dataset=dataset, batch_size=batch_size,
                                        output_path=output_path, sampler=train_sampler)
    test_data, _ = load_image_tf(dataset=dataset, batch_size=batch_size,
                                 output_path=output_path, sampler=test_sampler)
    val_data, _ = load_image_tf(dataset=dataset, batch_size=batch_size,
                                output_path=output_path, sampler=val_sampler)

    # to train final model
    if final:
        data, classes = load_image_tf(dataset=dataset, batch_size=batch_size, output_path=output_path)
        return data, network
    else:
        # to train on the train set and validate on the validation set
        if train:
            return train_data, val_data, network
        # to test on the test fold
        else:
            '''Combine train and validation sets'''
            print('******** Combining train + validation sets ... ')
            # combine train and validation indices for the sampler
            idx = np.concatenate([train_idx, val_idx])
            # define the sampler
            train_validation_sampler = SubsetRandomSampler(idx)
            # re-calculate class weights for the train+validation data
            class_weights = get_class_weights(dataset, idx)
            print('******** Sizes of data sets')
            print('=' * 100)
            print("=> Train + validation set size: {}".format(len(idx)))
            print('=> Class weights in train + validation: {}'.format(class_weights))
            print('=' * 100)
            # load train + validation data
            data, _ = load_image_tf(dataset=dataset,
                                    batch_size=batch_size, output_path=output_path, sampler=train_validation_sampler)

            return data, test_data, network