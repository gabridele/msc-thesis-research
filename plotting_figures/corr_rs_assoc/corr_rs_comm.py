import os
import glob
import re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import spearmanr

def compute_spearman_correlation(csv_path, npy_path):
    array_csv = pd.DataFrame.to_numpy(pd.read_csv(csv_path, header=None))
    array_npy = np.load(npy_path)
    
    assert array_csv.shape == array_npy.shape, "Arrays must be the same shape to compute Spearman correlation"
    
    upper_csv = np.triu(array_csv)
    upper_npy = np.triu(array_npy)
    csv_values = np.nan_to_num(upper_csv[np.triu_indices_from(upper_csv, k=1)].flatten())
    npy_values = np.nan_to_num(upper_npy[np.triu_indices_from(upper_npy, k=1)].flatten())

    correlation, p_value = spearmanr(csv_values, npy_values)

    return correlation, csv_values, npy_values

def plot_scatter(aw_values, fc_values, correlation, subject_id, avg=False):
    plt.figure()
    
    # Create scatter plot with tiny dark blue dots
    plt.scatter(aw_values, fc_values, color='#0047AB', s=4)  # s=10 for small dots
    
    # Add a regression line (line of best fit) with dark red
    m, b = np.polyfit(aw_values, fc_values, 1)  # Linear regression
    plt.plot(aw_values, m*aw_values + b, color='#D2042D')  # Dark red line

    # Title and labels
    title = f'{"Average" if avg else "Subject"} {subject_id}\nPearson\'s r: {correlation:.2f}'
    plt.title(title)
    plt.xlabel('Association Weight')
    plt.ylabel('Functional Connectivity')
    
    plt.tick_params(axis='both', which='major', labelsize=14)  # Major ticks
    plt.tick_params(axis='both', which='minor', labelsize=12)
    plt.grid(False)
    
    # Save the plot
    plot_filename = f'{"average_" if avg else "subject_"}{subject_id}_scatter_wholebrain.png'
    plt.savefig(plot_filename, bbox_inches='tight')
    plt.close()

    print(f'Saved scatter plot for {"average" if avg else "subject"} {subject_id} as {plot_filename}')

def process_files_and_compute_mean(csv_files):
    correlations = []
    groups = {'CTRL': [], 'SCZ': [], 'BPLR': [], 'ADHD': []}

    for csv_path in csv_files:
        # Extract subject ID from the CSV file path
        file_name = os.path.basename(csv_path)
        subject_id_match = re.search(r"sub-(\d+)", file_name)
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

        correlation, csv_values, npy_values = compute_spearman_correlation(csv_path, npy_path)
        plot_scatter(csv_values, npy_values, correlation, subject_id)

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
csv_pattern = os.path.join(os.getcwd(), 'derivatives', 'sub*', 'dwi', 'communicability_sub-*.csv')

# Find all CSV files matching the pattern
csv_files = glob.glob(csv_pattern)

# Compute mean correlations
overall_mean, group_means = process_files_and_compute_mean(csv_files)

# Save the results to a text file
output_file = "mean_spearman_correlations_comm-rs.txt"
with open(output_file, 'w') as f:
    f.write(f"Overall Mean Spearman Correlation: {overall_mean}\n")
    for group, mean in group_means.items():
        f.write(f"Mean Spearman Correlation for {group}: {mean}\n")

print(f"Results saved to {output_file}")
