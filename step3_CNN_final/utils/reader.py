# -*- coding: utf-8 -*-

"""
    Description:
        Supporting module for the utility.py module from utils
    Note:
        Parts of code are taken from https://pytorch.org/docs/ or various Internet sources

"""

# imports
import pandas as pd
import numpy as np
from PIL import Image
from torchvision.transforms.functional import pad
import matplotlib.pyplot as plt
import torch
from torch.autograd import Variable


def get_padding(image):
    """ Get how much padding should be applied to meet the desired width and height """
    max_w = 100
    max_h = 855
    imsize = image.size

    h_padding = (max_w - imsize[0]) / 2
    v_padding = (max_h - imsize[1]) / 2
    l_pad = h_padding if h_padding % 1 == 0 else h_padding + 0.5
    t_pad = v_padding if v_padding % 1 == 0 else v_padding + 0.5
    r_pad = h_padding if h_padding % 1 == 0 else h_padding - 0.5
    b_pad = v_padding if v_padding % 1 == 0 else v_padding - 0.5

    padding = (int(l_pad), int(t_pad), int(r_pad), int(b_pad))

    return padding


def csv_reader(path):
    """ To read a csv file"""
    with open(path, 'r') as file:
        reader = pd.read_csv(file, delimiter=',')
        reader = reader.to_numpy().astype(np.float32)
        #padded = np.pad(reader, ((padding[1], padding[3]), (padding[0], padding[2])))
    return reader


def image_reader(path):
    # Open path as file to avoid ResourceWarning (https://github.com/python-pillow/Pillow/issues/835)
    with open(path, 'rb') as f:
        img = Image.open(f)
        width, height = img.size
        if width != 100 or height != 855:
            padding = get_padding(img)
            img = pad(img, padding)
        return img.convert('L')


class ReshapeTransform:
    def __init__(self, new_size):
        self.new_size = new_size

    def __call__(self, img):
        return torch.reshape(img, self.new_size)


class PaddingChannelsTransform:
    def __init__(self, pad):
        self.pad = pad

    def __call__(self, img):
        padding = Variable(torch.zeros(self.pad, len(img[0]), len(img[0][0])))
        return torch.cat((img, padding), 0)


def show_image(image, ax=None, normalize=True):
  """Imshow for Tensor"""
  if ax is None:
      fig, ax = plt.subplots()

  image = image.numpy().transpose((1, 2, 0))

  if normalize:
      mean = np.array([0.485, 0.456, 0.406])
      std = np.array([0.229, 0.224, 0.225])
      image = std * image + mean
      image = np.clip(image, 0, 1)

  ax.imshow(image)
  ax.spines['top'].set_visible(False)
  ax.spines['right'].set_visible(False)
  ax.spines['left'].set_visible(False)
  ax.spines['bottom'].set_visible(False)
  ax.tick_params(axis='both', length=0)
  ax.set_xticklabels('')
  ax.set_yticklabels('')

  return ax