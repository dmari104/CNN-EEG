#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
    Description:
    Main script to test a CNN on each test fold from the cross-validation

    Call from the command line: python3 /step2_test_CNN.py /[data_folder_with_EEG_TF_segments]
    -s 'Loo' -b 64 -e 70 -l 0.0001 -i 0

    -i indicates the index of the seed to test on (in the range of 0-4)
    All command line arguments are specified in utils/utility.py

    Note: parts of code are taken from https://pytorch.org/docs/ or various Internet sources
"""

import torch
import os
from utils import utility
from utils.utility import parse_args
from model.evaluation import evaluate, matthews_cc, balanced_acc
from model.models import save_checkpoint

# Device configuration
global device
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')


def main():
    """Main function"""

    '''Parse data'''
    data, test_data, network = utility.parse_data(train=False)
    args = parse_args()

    '''Load network parameters from the last epoch'''
    # load the last states from the last epoch
    checkpoint = torch.load('../seeds/seed_{a}/epoch-{b}.pth.tar'.format(a=utility.seed, b=utility.max_epochs))
    network.net.load_state_dict(checkpoint['state_dict'])

    '''Run one additional epoch'''
    # one forward-backward pass on the train+validation data using previously loaded states from the last epoch
    print("******** Fitting the network...\n")
    network.net.train(True)
    optimizer = torch.optim.SGD(network.net.parameters(), lr=args.lr, momentum=0.9)
    #optimizer = torch.optim.AdamW(network.net.parameters(), lr=args.lr)
    print('******** Learning rate: ', args.lr)
    running_loss = 0.0
    train_examples = 0
    for i, (images, labels, paths) in enumerate(data):
        images = images.to(device)
        labels = labels.to(device)
        optimizer.zero_grad()
        # forward pass
        outputs = network.net(images)
        train_examples += labels.size(0)
        loss = network.criterion(outputs, labels)
        running_loss += loss.item()
        # backward pass and optimize
        loss.backward()
        optimizer.step()
    # get average loss on the train + validation data
    overall_loss = running_loss / len(data)
    print('=> Train loss: ', overall_loss)
    print('\n')

    '''Evaluate on the test fold'''
    # evaluate the network on the hold-out test set
    print("******** Evaluation on the test set...")
    print('=' * 100)
    test_scores, test_loss, test_prob, test_classes, img_paths = \
        evaluate(test_data, network.net, utility.classes, network.criterion)
    print('=> Test set confusion scores ', test_scores)
    print('=> MCC: ', matthews_cc(test_scores))
    print('=> Balanced acc: ', balanced_acc(test_scores))
    print('=> Average loss: {}\n'.format(test_loss))
    print('=' * 100)
    # save results
    save_checkpoint({
        'state_dict': network.net.state_dict(),
        'network_loss': overall_loss,
        'test_loss': test_loss,
        'optimizer': optimizer.state_dict(),
        'test_confusion_matrix': test_scores,
        'test_probabilities': test_prob,
        'test_true_classes': test_classes,
        'image_paths': img_paths
    }, utility.test_dir, os.path.join(utility.test_dir, 'test_eval.pth.tar'))


if __name__ == '__main__':
    main()