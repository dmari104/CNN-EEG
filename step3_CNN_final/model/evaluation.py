
import torch
import math
import torch.nn.functional as F


# Device configuration
global device
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
#device = torch.device('cpu')


def evaluate(xy_data, model, classes, criterion):
    model.eval()
    with torch.no_grad():
        n_classes = len(classes)  # number of classes (=2)
        n_examples = 0  # number of instances in the validation set
        n_correct = 0  # total number of correctly classified
        n_class_correct = [0] * n_classes  # number of correctly classified per class
        n_class_wrong = [0] * n_classes  # number of wrongly classified per class
        n_class_examples = [0] * n_classes  # total number of instances per class
        loss_examples = 0.0
        probabilities = torch.empty(0, n_classes).to(device)
        true_classes = torch.empty(0, 1).long().to(device)
        img_paths = []
        # loop over mini-batches
        for images, labels, paths in xy_data:
            images = images.to(device)
            labels = labels.to(device)
            img_paths.extend(list(paths))
            # forward pass - scores
            outputs = model(images)
            # probabilities via softmax
            probs = F.softmax(outputs, dim=1)
            # calculate validation loss in the mini-batch
            loss = criterion(outputs, labels)
            # get classification for each instance in the mini-batch (max probability and corresponding class)
            prediction, prediction_class_idx = torch.max(probs, 1)
            # true classes
            true = labels.view(-1, 1)
            # store
            true_classes = torch.cat((true_classes, true), 0)
            probabilities = torch.cat((probabilities, probs), 0)
            # number of instances in the mini-batch
            n_examples += labels.size(0)
            # number of correct classifications
            n_correct += (prediction_class_idx == labels).sum().item()
            loss_examples += loss.item()
            # loop over instances
            for i in range(images.size()[0]):
                # label
                label = labels[i]
                # prediction
                pred = prediction_class_idx[i]
                # number of correct and wrong per class
                if (label == pred):
                    n_class_correct[label] += 1
                else:
                    n_class_wrong[label] += 1
                # number of total instances per class
                n_class_examples[label] += 1
        # accuracy
        acc = 100.0 * n_correct/n_examples
        print(f'******** Accuracy of the network: {acc: .4f} %')
        # confusion table scores (TP, FP, TN, FN, P, N)
        scores = [n_class_correct[0], n_class_wrong[1], n_class_correct[1], n_class_wrong[0],
                  n_class_examples[0], n_class_examples[1]]
        # loss over all mini-batches
        loss_examples = loss_examples / len(xy_data)
        # accuracy per class
        for i in range(n_classes):
            acc = 100.0 * n_class_correct[i] / n_class_examples[i]
            print(f'******** Accuracy of {classes[i]}: {acc: .4f} %')

    return scores, loss_examples, probabilities, true_classes, img_paths


def matthews_cc(scores):
    """scores = [tp, fp, tn, fn, total_p, total_n]"""
    mcc = (scores[0]*scores[2] - scores[1]*scores[3])/(
        math.sqrt((scores[0]+scores[1])*(scores[0]+scores[3])*(scores[2]+scores[1])*(scores[2]+scores[3])))

    return mcc


def f1_score(scores):
    f1 = (2*scores[0])/(2*scores[0] + scores[3] + scores[1])

    return f1


def balanced_acc(scores):
    bal_acc = (scores[0]/scores[4] + scores[2]/scores[5])/2

    return bal_acc