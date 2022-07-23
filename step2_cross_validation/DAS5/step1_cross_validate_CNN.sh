#!/bin/bash
#SBATCH --time=20:00:00
#SBATCH --job-name=crossval_cnn
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH -C TitanX
#SBATCH --gres=gpu:1
#SBATCH --output=cnn.ASGD.SBambi.LOO.%j.out

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
python3 /home/mdo520/experiments/eeg/loo_cnn/step1_cross_validate_CNN.py /var/scratch/mdo520/data/SBAMBI -s 'Loo' -b 64 -e 70 -l 0.0001 -i 0

# to resume, add -r
# -i indicates the index of the seed to train with (in the range of 0-4)



