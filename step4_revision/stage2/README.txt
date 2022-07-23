# Here, we will process the revision from the previous stage to generate revised TF EEG segments (for CNN-r)

# The order of script execution is indicated with prefix step#_

# data/segments_to_review - txt files with the selected EEG segments to be revised produced at the previous stage
# data/reviewed folder contains selected EEG segments and their revised labels.
 

# step1_process_revision.py - process revision output from the previous stage to generate data frames with revised segments (+ segments for which one or both raters were uncertain -> they will stay with their original label; + segments which one or both raters labeled as related to drowsiness -> they will be ignored)

# step2_generate_revised_TFsegments.py - to generate the revised dataset (not-selected-for-revision data with their original labels and selected-for-revision data with revised labels). 





