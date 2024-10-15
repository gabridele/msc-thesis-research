import os
import glob
import re
import numpy as np
import pandas as pd
from scipy.stats import spearmanr

def compute_spearman_correlation(csv_path, npy_path):
    array_csv = pd.DataFrame.to_numpy(pd.read_csv(csv_path, header=None))
    array_npy = np.load(npy_path)
    
    assert array_csv.shape == array_npy.shape, "Arrays must be the same shape to compute Spearman correlation"
    
    vector_csv = array_csv.flatten()
    vector_npy = array_npy.flatten()

    correlation, p_value = spearmanr(vector_csv, vector_npy)

    return correlation

def process_files_and_compute_mean(csv_files):
    correlations = []
    groups = {'CTRL': [], 'SCZ': [], 'BPLR': [], 'ADHD': []}

    for csv_path in csv_files:
        # Extract subject ID from the CSV file path
        file_name = os.path.basename(csv_path)
        subject_id_match = re.search(r"sub-(\d+)_", file_name)
        if not subject_id_match:
            print(f"Subject ID not found in file name: {csv_path}")
            continue
        subject_id = subject_id_match.group(1)
        # Construct the NPY file path using the subject ID

        npy_file_name = f"restored_functional_connectivity_sub-{subject_id}.npy"
        npy_path = os.path.join(os.getcwd(), 'derivatives', f'sub-{subject_id}', 'func', npy_file_name)
        if not os.path.exists(npy_path):
            print(f"Matching NPY file not found for {csv_path}")
            continue

        correlation = compute_spearman_correlation(csv_path, npy_path)
        print(subject_id, correlation)
        correlations.append(correlation)
        
        # Classify the subject into groups based on the ID
        if subject_id.startswith('1'):
            groups['CTRL'].append(correlation)
        elif subject_id.startswith('5'):
            groups['SCZ'].append(correlation)
        elif subject_id.startswith('6'):
            groups['BPLR'].append(correlation)
        elif subject_id.startswith('7'):
            groups['ADHD'].append(correlation)

    overall_mean = np.mean(correlations)
    group_means = {group: np.mean(corrs) if corrs else float('nan') for group, corrs in groups.items()}

    return overall_mean, group_means

# Define the path pattern for CSV files
csv_pattern = os.path.join(os.getcwd(), 'derivatives', 'sub*', 'dwi', 'restored_full_association_matrix_sub-*_40seeds.csv')

# Find all CSV files matching the pattern
csv_files = glob.glob(csv_pattern)

# Compute mean correlations
overall_mean, group_means = process_files_and_compute_mean(csv_files)

# Save the results to a text file
output_file = "mean_spearman_correlations_aw40-rs.txt"
with open(output_file, 'w') as f:
    f.write(f"Overall Mean Spearman Correlation: {overall_mean}\n")
    for group, mean in group_means.items():
        f.write(f"Mean Spearman Correlation for {group}: {mean}\n")

print(f"Results saved to {output_file}")
