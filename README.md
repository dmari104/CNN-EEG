# CNN-EEG
Code for the manuscript "Improved manual annotation of EEG signals through convolutional neural network guidance" by Marina Diachenko, Simon J. Houtman, Erika L. Juarez-Martinez, Jennifer R. Ramautar, Robin Weiler, Huibert D. Mansvelder, Hilgo Bruining, Peter Bloem, Klaus Linkenkaer-Hansen.

Correspondence should be addressed to Klaus Linkenkaer-Hansen, klaus.linkenkaer@cncr.vu.nl

Questions about the code should be addressed to Marina Diachenko, m.diachenko@vu.nl


This directory contains the main steps of the pipeline. Workflow is indicated with prefix step#_.

Short descritpion:
1. final_models/ folder contains serialised final models (CNN, CNN-rnd, CNN-r, and CNN-rrnd) that were trained on the entire SPACE/BAMBI dataset (original gold standard, randomly-shuffled gold standard, expert-revised gold standard, and randomly-revised gold standard, respectively). For more details, see the manuscript.

2. After the revision step (step 4), CNN-rnd, CNN-r, and CNN-rrnd were cross-validated using the same scripts from step 2 (cross validation of CNN), with paths to the dataset folder changed accordingly.

3. Training and testing were performed on DAS5 VU cluster. All data and scripts were transferred to the cluster first.

4. Unfortunately, the data are private and cannot be shared with public.
