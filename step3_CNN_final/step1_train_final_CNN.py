#!/usr/bin/python3

"""
    Description:
    Main script to train a final CNN on the entire dataset without splits

    Call from the command line: python3 /step1_train_final_CNN.py /[data_folder_with_EEG_TF_segments]
    -b 64 -e 100 -l 0.0001 -f

    -f indicates that a final model should be trained

    Note: parts of code are taken from https://pytorch.org/docs/ or various Internet sources
"""

import torch
import numpy as np
import os

# import local modules
from utils import utility
from model.evaluation import evaluate
from model.models import save_checkpoint, model_summary

# Device configuration
global device
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')


def get_lr(optimizer):
    for param_group in optimizer.param_groups:
        return param_group['lr']


def run_epoch(train_data, model):

    running_loss = 0.0
    train_examples = 0
    # track the training loss as the model trains
    train_losses = []

    model.net.train(True)
    print('learning rate: ', get_lr(model.optimizer))
    for i, (images, labels, paths) in enumerate(train_data):
        images = images.to(device)
        labels = labels.to(device)

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

        if (i + 1) % 1 == 0:
            utility.writer.add_scalar('Training loss',
                              running_loss / 1,
                              (epoch - 1) * len(train_data) + i)
            running_loss = 0.0

    train_loss = np.sum(train_losses) / len(train_data)

    save_checkpoint({
        'epoch': epoch,
        'state_dict': model.net.state_dict(),
        'train_loss': train_loss,
        'train_losses': train_losses,
        'optimizer': model.optimizer.state_dict(),
        'optimizer_params': model.optimizer.param_groups
    }, utility.train_dir, os.path.join(utility.train_dir, 'epoch-{}.pth.tar'.format(epoch)))
    print('\n')

    return train_loss


def main():
    # process arguments and load specified files

    """Main function"""

    '''Parse data'''
    data, network = utility.parse_data()

    '''Train'''
    # track average training loss per epoch
    avg_train_losses = []
    epoch_len = len(str(utility.max_epochs))
    model_summary(network.net)

    global epoch

    if utility.resume:
        resume_epoch = 62
        checkpoint = torch.load('../seeds/seed_{a}/epoch-{b}.pth.tar'.format(a=utility.seed, b=resume_epoch))
        network.net.load_state_dict(checkpoint['state_dict'])
        i = resume_epoch + 1
    else:
        i = 1

    # train the network on the entire dataset
    for epoch in range(1, utility.max_epochs + 1):
        print(f'############ Epoch %d out of %d' % (epoch, utility.max_epochs))
        # get average train loss from one epoch
        train_loss = run_epoch(data, network)
        # store
        avg_train_losses.append(train_loss)

        print_msg = (f'[{epoch:>{epoch_len}}/{utility.max_epochs:>{epoch_len}}] ' +
                     f'train_loss: {train_loss:.5f} ')
        print(print_msg)

    # get train fit
    train_scores, train_loss, train_prob, train_classes, img_paths = \
        evaluate(data, network.net, utility.classes, network.criterion)
    print('=> Average train set loss: {}\n'.format(train_loss))

    # save results
    save_checkpoint({
        'state_dict': network.net.state_dict(),
        'train_loss': train_loss,
        'optimizer': network.optimizer.state_dict(),
        'train_confusion_matrix': train_scores,
        'train_probabilities': train_prob,
        'train_true_classes': train_classes,
        'image_paths': img_paths
    }, utility.output_path, os.path.join(utility.output_path, 'final_CNN.pth.tar'))


if __name__ == '__main__':
    main()