#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
    Description:
    Main script to cross-validate a CNN on TF EEG images of artifacts and non-artifacts

    Call from the command line: python3 /step1_cross_validate_CNN.py /[data_folder_with_EEG_TF_segments]
    -s 'Loo' -b 64 -e 70 -l 0.0001 -i 0

    -i indicates the index of the seed to train with (in the range of 0-4)
    All command line arguments are specified in utils/utility.py

    Note: parts of code are taken from https://pytorch.org/docs/ or various Internet sources
"""

import torch
import numpy as np
import os
import torch.nn.functional as F

# import local modules
from utils import utility
from model.models import save_checkpoint, save_best, EarlyStopping

# Device configuration
global device
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')


def get_lr(optimizer):
    """ Function to get the provided learning rate parameter """
    for param_group in optimizer.param_groups:
        return param_group['lr']


def validate(val_data, model):
    """ Function to validate the network on the validation set """

    # track validation loss
    val_losses = []
    # set validation mode
    model.net.eval()
    # no gradients
    with torch.no_grad():
        n_classes = len(utility.classes)    # number of classes (=2)
        n_examples = 0  # number of instances in the validation set
        n_correct = 0   # total number of correctly classified
        n_class_correct = [0] * n_classes   # number of correctly classified per class
        n_class_wrong = [0] * n_classes     # number of wrongly classified per class
        n_class_examples = [0] * n_classes  # total number of instances per class
        # loop over mini-batches
        for i, (images, labels, paths) in enumerate(val_data):
            images = images.to(device)
            labels = labels.to(device)
            # forward pass - scores
            outputs = model.net(images)
            # probabilities via softmax
            probabilities = F.softmax(outputs, dim=1)
            # calculate validation loss in the mini-batch
            loss = model.criterion(outputs, labels)
            # record validation loss
            val_losses.append(loss.item())
            # get classification for each instance in the mini-batch (max probability and corresponding class)
            prediction, prediction_class_idx = torch.max(probabilities, 1)
            # number of instances in the mini-batch
            n_examples += labels.size(0)
            # number of correct classifications
            n_correct += (prediction_class_idx == labels).sum().item()
            # loop over instances
            for i in range(images.size()[0]):
                # label
                label = labels[i]
                # prediction
                pred = prediction_class_idx[i]
                # number of correct and wrong per class
                if label == pred:
                    n_class_correct[label] += 1
                else:
                    n_class_wrong[label] += 1
                # number of total instances per class
                n_class_examples[label] += 1
        # validation accuracy
        acc = 100.0 * n_correct / n_examples
        print(f'******** Validation accuracy of the network: {acc: .4f} %')
        # accuracy per class
        for i in range(n_classes):
            acc = 100.0 * n_class_correct[i] / n_class_examples[i]
            print(f'******** Validation accuracy of {utility.classes[i]}: {acc: .4f} %')
        # confusion table scores (TP, FP, TN, FN, P, N)
        scores = [n_class_correct[0], n_class_wrong[1], n_class_correct[1], n_class_wrong[0], n_class_examples[0],
                  n_class_examples[1]]

    # validation loss over all mini-batches
    val_loss = np.sum(val_losses) / len(val_data)

    return val_loss, scores


def run_epoch(train_data, val_data, model):
    """ Function to run one epoch on the training dataset """

    running_loss = 0.0
    train_examples = 0
    # track training loss
    train_losses = []
    iterations = len(train_data)

    # set train mode
    model.net.train(True)
    print('******** Learning rate: {}'.format(get_lr(model.optimizer)))

    # run epoch
    for i, (images, labels, _) in enumerate(train_data):
        # data and labels to gpu
        images = images.to(device)
        labels = labels.to(device)
        # zero the gradients
        model.optimizer.zero_grad()

        # forward pass
        outputs = model.net(images)
        train_examples += labels.size(0)
        loss = model.criterion(outputs, labels)
        running_loss += loss.item()
        train_losses.append(loss.item())

        # backward pass and optimize
        loss.backward()
        model.optimizer.step()

        # write to tensorboard
        if (i + 1) % 100 == 0:
            utility.writer.add_scalar('Training loss',
                              running_loss / 1,
                              (epoch - 1) * len(train_data) + i)
            running_loss = 0.0

    # calculate train loss
    train_loss = np.sum(train_losses) / len(train_data)
    # get validation loss and confusion table scores
    val_loss, scores = validate(val_data, model)

    if model.scheduler is not None:
        model.scheduler.step(val_loss)

    # write to tensorboard
    utility.writer.add_scalar('Validation loss', val_loss, epoch)

    # save model and losses
    save_checkpoint({
        'epoch': epoch,
        'state_dict': model.net.state_dict(),
        'val_loss': val_loss,
        'train_loss': train_loss,
        'train_losses': train_losses,
        'optimizer': model.optimizer.state_dict(),
        'optimizer_params': model.optimizer.param_groups,
        'val_confusion_matrix': scores
    }, utility.train_dir, os.path.join(utility.train_dir, 'epoch-{}.pth.tar'.format(epoch)))

    return train_loss, val_loss


def main():
    """Main function"""

    global epoch

    '''Parse data'''
    train_data, val_data, network = utility.parse_data()

    '''Train'''
    # track average training loss per epoch
    avg_train_losses = []
    # track average validation loss per epoch
    avg_val_losses = []
    epoch_len = len(str(utility.max_epochs))
    # define early stopping
    early_stopping = EarlyStopping(patience=80, verbose=True)

    # if want to resume training from the last epoch
    if utility.resume:
        resume_epoch = 35
        '''Load network parameters from the last epoch'''
        # load the last states from the last epoch
        checkpoint = torch.load(
            '../seeds/seed_{a}/epoch-{b}.pth.tar'.format(a=utility.seed, b=resume_epoch))
        network.net.load_state_dict(checkpoint['state_dict'])
        i = resume_epoch + 1
    else:
        i = 1

    # train the network on the train set for max number of epochs
    for epoch in range(i, utility.max_epochs + 1):
        print(f'############ Epoch %d out of %d' % (epoch, utility.max_epochs))
        # get average train and validation losses from one epoch
        train_loss, val_loss = run_epoch(train_data, val_data, network)
        # store
        avg_train_losses.append(train_loss)
        avg_val_losses.append(val_loss)

        print_msg = (f'[{epoch:>{epoch_len}}/{utility.max_epochs:>{epoch_len}}] ' +
                     f'train_loss: {train_loss:.5f}; ' +
                     f'valid_loss: {val_loss:.5f}')
        print(print_msg)

        # access the network for early stopping
        early_stopping(val_loss, network.net)
        if early_stopping.early_stop:
            print("Early stopping")
            save_best(os.path.join(utility.train_dir, 'epoch-{}.pth.tar'.format(epoch - early_stopping.counter)))
            break
        print('\n')


if __name__ == '__main__':
    main()
