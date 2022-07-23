# Here, 5-fold cross-validation with leave-20%-out subject-wise split is performed

# The order of script execution is indicated with prefix step#_

# model/ and utils/ folders contain helper function to be used with the main scripts

# DAS5/ folder contains jobs to be scheduled on the server for the experiments

# step1_cross_validate_CNN.py - to train a CNN on a training fold (80% of the data). Split is performed to take EEG segments of 20% of the subjects out for the test and validation sets. 5-fold cross-validation means 5 splits are performed with different subjects being taken out each time without repetition. Split number is indicated with the command line argument -i (which can be between 0 and 4). See the first comment inside the script for more info. 

# step2_test_CNN.py - to test a trained CNN on the test fold. Split number is indicated with the command line argument -i (which can be between 0 and 4). E.g., a model is trained on the first fold (split i=0) and should be tested on the corresponding test fold (split i=0). See the first comment inside the script for more info. 


