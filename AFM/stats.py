import os
import glob
import re
import numpy as np


def get_spearman_correlation(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
        # given second line is spearman corr
        spearman_line = lines[1].strip()
        match = re.search(r"spearman_corr:\s*(-?[\d\.]+)", spearman_line)

        if match:
            return float(match.group(1))
        else:
            raise ValueError(f"Spearman correlation not found in file {file_path}")

def compute_mean_correlations(directory):
    file_pattern = os.path.join(directory, "*.txt")
    files = glob.glob(file_pattern)
    
    correlations = []
    groups = {'CTRL': [], 'SCZ': [], 'BPLR': [], 'ADHD': []}

    for file_path in files:
        correlation = get_spearman_correlation(file_path)
        correlations.append(correlation)
        
        # Determine the subject group based on the filename
        file_name = os.path.basename(file_path)
        subject_id = re.search(r"sub-(\d+)_", file_name).group(1)
        
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

# directory with text files
directory = os.getcwd()

# compute mean correlations
overall_mean, group_means = compute_mean_correlations(directory)

output_file = "mean_spearman_correlations.txt"
with open(output_file, 'w') as f:
    f.write(f"Overall Mean Spearman Correlation: {overall_mean}\n")
    for group, mean in group_means.items():
        f.write(f"Mean Spearman Correlation for {group}: {mean}\n")

print(f"Results saved to {output_file}")
