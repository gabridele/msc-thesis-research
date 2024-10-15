import numpy as np
import os

# Base directory containing the files
base_dir = '/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/'

# Function to check for NaN values in a numpy array
def check_for_nan(file_path, log_file):
    array = np.load(file_path)
    if np.any(np.isnan(array)):
        log_file.write(f"{file_path} contains NaN values.\n")

# Output log file
log_file_path = 'nan_files.txt'

# Open the log file for writing
with open(log_file_path, 'w') as log_file:
    # List all subdirectories in the base directory
    sub_dirs = [d for d in os.listdir(base_dir) if os.path.isdir(os.path.join(base_dir, d))]

    # Iterate over each subdirectory and check the respective file for NaN values
    for sub_dir in sub_dirs:
        func_dir = os.path.join(base_dir, sub_dir, 'func')
        file_name = f"{sub_dir}_rs_correlation_matrix.npy"
        file_path = os.path.join(func_dir, file_name)
        
        if os.path.exists(file_path):
            check_for_nan(file_path, log_file)
        else:
            log_file.write(f"{file_path} does not exist.\n")

print(f"Results saved to {log_file_path}")
