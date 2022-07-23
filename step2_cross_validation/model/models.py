
import torch
import shutil
import os
import numpy as np


class Model:
    def __init__(self, net, optimizer, criterion):
        self.net = net
        self.optimizer = optimizer
        self.criterion = criterion


def save_checkpoint(state, checkpoint, filepath):
    """ Saves model and training parameters at checkpoint + 'epoch-{}.pth.tar'
        Args:
            state: (dict) contains model's state_dict, may contain other keys such as epoch, optimizer state_dict
            checkpoint: (string) folder where parameters are to be saved
            filepath: (string)
    """
    if not os.path.exists(checkpoint):
        print("Checkpoint Directory does not exist! Making directory {}".format(checkpoint))
        os.mkdir(checkpoint)
    torch.save(state, filepath)
    print("Checkpoint has been saved!")


def save_best(filepath):
    new_filepath = filepath.replace('.pth.tar', '_best.pth.tar')
    shutil.copyfile(filepath, new_filepath)
    print("Best model saved!")


class EarlyStopping:
    """Early stops the training if validation loss doesn't improve after a given patience."""
    def __init__(self, patience=15, verbose=False, delta=0):
        """
        Args:
            patience (int): How long to wait after last time validation loss improved.
                            Default: 7
            verbose (bool): If True, prints a message for each validation loss improvement.
                            Default: False
            delta (float): Minimum change in the monitored quantity to qualify as an improvement.
                            Default: 0
        """
        self.patience = patience
        self.verbose = verbose
        self.counter = 0
        self.best_score = None
        self.early_stop = False
        self.val_loss_min = np.Inf
        self.delta = delta

    def __call__(self, val_loss, model):

        score = -val_loss

        if self.best_score is None:
            self.best_score = score
            self.save_checkpoint(val_loss, model)
        elif score < self.best_score + self.delta:
            self.counter += 1
            print(f'EarlyStopping counter: {self.counter} out of {self.patience}')
            if self.counter >= self.patience:
                self.early_stop = True
        else:
            self.best_score = score
            self.save_checkpoint(val_loss, model)
            self.counter = 0

    def save_checkpoint(self, val_loss, model):
        '''Saves model when validation loss decrease.'''
        if self.verbose:
            print(f'Validation loss decreased ({self.val_loss_min:.6f} --> {val_loss:.6f}).  Saving model ...')
        torch.save(model.state_dict(), 'checkpoint.pt')
        self.val_loss_min = val_loss


def model_summary(model):
    print("******** Network summary")
    print()
    print("Layer_name" + "\t" * 7 + "Number of Parameters")
    print("=" * 100)
    model_parameters = [layer for layer in model.parameters() if layer.requires_grad]
    layer_name = [child for child in model.children()]
    j = 0
    total_params = 0
    print("\t" * 10)
    for i in layer_name:
        print()
        param = 0
        try:
            bias = (i.bias is not None)
        except:
            bias = False
        if not bias:
            param = model_parameters[j].numel() + model_parameters[j + 1].numel()
            j = j + 2
        else:
            param = model_parameters[j].numel()
            j = j + 1
        print(str(i) + "\t" * 3 + str(param))
        total_params += param
    print("=" * 100)
    print(f"Total Params:{total_params}")