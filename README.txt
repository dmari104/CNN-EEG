# This folder contains the main steps of the pipeline for "Improved manual annotation of EEG signals through convolutional neural network guidance" manuscript

# Workflow is indicated with prefix step#_

# final_models/ folder contains serialised final models (CNN, CNN-rnd, CNN-r, and CNN-rrnd) that were trained on the entire SPACE/BAMBI dataset (original gold standard, randomly shuffled gold standard, expert-revised gold standard, and randomly-revised gold standard, respectively). For more details, see the manuscript

# After the revision step (step 4), CNN-rnd, CNN-r, and CNN-rrnd were cross-validated using the same scripts from step 2 (cross validation of CNN), with paths to the dataset folder changed accordingly

# Training and testing were performed on DAS5 VU cluster. All data and scripts were transferred to the cluster first

# Unfortunately, the data are private and cannot be shared with public.




