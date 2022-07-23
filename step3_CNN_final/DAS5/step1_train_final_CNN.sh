#!/bin/bash
#SBATCH --time=30:00:00
#SBATCH --job-name=final_CNN
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH -C TitanX
#SBATCH --gres=gpu:1
#SBATCH --output=CNN.Final.ASGD.SBAMBI.%j.out

module load cuda10.1/toolkit
module load cuDNN/cuda10.1

source /home/mdo520/.bashrc

# Base directory for the experiment
cd /var/scratch/mdo520/output

# Simple trick to create a unique directory for each run of the script
echo $$
mkdir o`echo $$`
cd o`echo $$`

# Copy files to the node's local file system
# cp -r /var/scratch/mdo520/data/SBAMBI /local/mdo520/

# Run the actual experiment 
python3 /home/mdo520/experiments/eeg/cnn/step1_train_final_CNN.py /var/scratch/mdo520/data/SBAMBI -b 64 -e 100 -l 0.0001 -f

# to resume, add -r
# with -i, indicate the index of the seed to resume with



