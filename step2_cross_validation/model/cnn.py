# -*- coding: utf-8 -*-

# imports
import torch
from torch.nn import Linear, ReLU, Sequential, Conv2d, MaxPool2d, MaxPool3d, Module

# Ignore warnings
import warnings
warnings.filterwarnings("ignore")


# Implement ConvNet with 3D convolution and 3 layers
class ConvNet2D(Module):
    def __init__(self, num_classes, h, w, num_channels, groups):
        super(ConvNet2D, self).__init__()
        """d = 1, h = 45, w = 100"""

        self.n_filters1 = 50
        self.n_filters2 = 100
        self.n_filters3 = 150
        kernel1 = (1, 5)  # kernel of the 1st convolution
        stride1 = 1  # stride for the 1st convolution
        pooling1 = (1, 2, 2)  # max pooling after 1st convolution + ReLU activation
        kernel2 = (5, 5)  # kernel of the 2nd convolution
        stride2 = 1  # stride for the 2nd convolution
        pooling2 = (1, 2, 2)  # max pooling after 2nd convolution + ReLU activation
        kernel3 = (3, 3)  # kernel of the 3rd convolution
        stride3 = 1  # stride for the 3rd convolution
        pooling3 = (1, 1, 1)  # max pooling after 3rd convolution + ReLU activation
        padding = 0  # zero padding everywhere

        self.cnn_layer1 = torch.nn.Sequential()
        self.cnn_layer1.add_module('Conv1',
                                   Conv2d(num_channels, groups*self.n_filters1, groups=groups, kernel_size=kernel1, stride=stride1, padding=padding))
        self.cnn_layer1.add_module('ReLU1', ReLU(inplace=True))
        self.cnn_layer1.add_module("MaxPool1", MaxPool3d(kernel_size=pooling1, stride=pooling1))
        self.cnn_layer2 = torch.nn.Sequential()
        self.cnn_layer2.add_module('Conv2',
                                   Conv2d(groups*self.n_filters1, groups*self.n_filters2, groups=self.n_filters1, kernel_size=kernel2, stride=stride2,
                                          padding=padding))
        self.cnn_layer2.add_module('ReLU2', ReLU(inplace=True))
        self.cnn_layer2.add_module("MaxPool2", MaxPool3d(kernel_size=pooling2, stride=pooling2))
        self.cnn_layer3 = torch.nn.Sequential()
        self.cnn_layer3.add_module('Conv3',
                                   Conv2d(groups*self.n_filters2, self.n_filters3, kernel_size=kernel3, stride=stride3,
                                          padding=padding))
        self.cnn_layer3.add_module('ReLU3', ReLU(inplace=True))
        self.cnn_layer3.add_module("MaxPool3", MaxPool3d(kernel_size=pooling3, stride=pooling3))

        # Calculate output size after the 1st convolution + ReLU + max pooling
        output1 = convolution_output(h, w, kernel1, stride1, padding, pooling1)
        # Calculate output size after the 2nd convolution + ReLU + max pooling
        output2 = convolution_output(output1[0], output1[1], kernel2, stride2, padding, pooling2)
        # Calculate output size after the 3rd convolution + ReLU + max pooling
        self.output3 = convolution_output(output2[0], output2[1], kernel3, stride3, padding, pooling3)

        # Define one fully connected linear layer
        self.linear_layers = Linear(self.n_filters3 * self.output3[0] * self.output3[1], num_classes)

    # Define the forward pass
    def forward(self, x):
        x = self.cnn_layer1(x)
        x = self.cnn_layer2(x)
        x = self.cnn_layer3(x)
        x = x.view(-1, self.n_filters3 * self.output3[0] * self.output3[1])
        x = self.linear_layers(x)
        return x


def convolution_output(h, w, kernel, stride, padding, pooling):

    output_size = (int((h + 2 * padding - kernel[0]) / stride + 1), int((w + 2 * padding - kernel[1]) / stride + 1))
    output_size = (int(output_size[0] / pooling[1]), int(output_size[1] / pooling[2]))

    return output_size
