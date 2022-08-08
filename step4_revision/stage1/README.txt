# Here, false positive and false negative segments as predicted by the final CNN model (according to the original gold standard) will be selected for revision, and revision will be done.

# The order of script execution is indicated with prefix step#_

# helperfunctions/ contains supporting functions for the main scripts

# Software/ contains eeglab toolbox. 

# data/segments_to_review - output data produced by step1_select_segments.py
# data/fn_segments.mat and data/fp_segments.mat - EEG segments selected for revision + meta info (output of step2_extract_fn_segments.m and step2_extract_fp_semgnets.m). Provided as is since original recordings needed to produce signal segments and meta info are private and cannot be shared.
# data/reviewed folder contains selected EEG segments and their revised labels.
 

# step1_select_segments_CNN.py - segments that were falsely predicted by the CNN model plus segments adjacent to them in time will be selected for revision. Selection of false positive segments is based on the threshold probability of 0.65 and of false negative segments - on the threshold probability of 0.4. Adjacent segments are selected irrespective of their predicted probability.

# step2_extract_fn_segments.m and step2_extract_fp_segments.m - based on the selection from step1 script, EEG signal segments and meta info for expert revision will be produced in MATLAB

# step3_review_segments_1.m and step3_review_segments_2.m - to launch a custom-made Matlab viewer (Monkey Cleaner) to revise selected EEG segments. A new version of Monkey Cleaner in Python is currently being developed to make things compatible with MNE and avoid the necessity of converting between MATLAB and Python all the time. 





