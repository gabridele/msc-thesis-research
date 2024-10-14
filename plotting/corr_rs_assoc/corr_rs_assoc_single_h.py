import os
import glob
import re
import numpy as np
import pandas as pd
from scipy.stats import spearmanr
import matplotlib.pyplot as plt

def compute_spearman_correlation_h(csv_path, npy_path):

    array_csv = pd.DataFrame.to_numpy(pd.read_csv(csv_path, header=None))
    array_npy = np.load(npy_path)
    
    assert array_csv.shape == array_npy.shape, "Arrays must be the same shape to compute Spearman correlation"
    
    upper_csv = np.triu(array_csv)
    upper_npy = np.triu(array_npy)

    lh_csv = upper_csv[27:254, 27:254]

    rh_csv = np.vstack((upper_csv[:27], upper_csv[254:454]))
    rh_csv = np.hstack((rh_csv[:, :27], rh_csv[:, 254:454]))


    lh_csv_values = np.nan_to_num(lh_csv[np.triu_indices_from(lh_csv, k=1)].flatten())
    rh_csv_values = np.nan_to_num(rh_csv[np.triu_indices_from(rh_csv, k=1)].flatten())

    lh_npy = upper_npy[27:254, 27:254]
    print(lh_npy.shape)
    rh_npy = np.vstack((upper_npy[:27], upper_npy[254:454]))
    rh_npy = np.hstack((rh_npy[:, :27], rh_npy[:, 254:454]))

    print(rh_npy.shape)
    lh_npy_values = np.nan_to_num(lh_npy[np.triu_indices_from(lh_npy, k=1)].flatten())
    rh_npy_values = np.nan_to_num(rh_npy[np.triu_indices_from(rh_npy, k=1)].flatten())

    correlation_lh, p_value_lh = spearmanr(lh_csv_values, lh_npy_values)
    correlation_rh, p_value_rh = spearmanr(rh_csv_values, rh_npy_values)
    return correlation_lh, correlation_rh, lh_csv_values, rh_csv_values, lh_npy_values, rh_npy_values

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
    plot_filename = f'{"average_" if avg else "subject_"}{subject_id}_scatter_whole_right.png'
    plt.savefig(plot_filename, bbox_inches='tight')
    plt.close()

    print(f'Saved scatter plot for {"average" if avg else "subject"} {subject_id} as {plot_filename}')

def process_files_and_compute_mean(csv_files):
    correlations_lh = []
    correlations_rh = []
    groups_lh = {'CTRL': [], 'SCZ': [], 'BPLR': [], 'ADHD': []}
    groups_rh = {'CTRL': [], 'SCZ': [], 'BPLR': [], 'ADHD': []}

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

        correlation_lh, correlation_rh, lh_csv_values, rh_csv_values, lh_npy_values, rh_npy_values = compute_spearman_correlation_h(csv_path, npy_path)
        plot_scatter(rh_csv_values, rh_npy_values, correlation_rh, subject_id)
        
        print(subject_id, correlation_lh, correlation_rh)
        correlations_lh.append(correlation_lh)
        correlations_rh.append(correlation_rh)
        
        # Classify the subject into groups based on the ID
        if subject_id.startswith('1'):
            groups_lh['CTRL'].append(correlation_lh)
        elif subject_id.startswith('5'):
            groups_lh['SCZ'].append(correlation_lh)
        elif subject_id.startswith('6'):
            groups_lh['BPLR'].append(correlation_lh)
        elif subject_id.startswith('7'):
            groups_lh['ADHD'].append(correlation_lh)

        # Classify the subject into groups based on the ID
        if subject_id.startswith('1'):
            groups_rh['CTRL'].append(correlation_rh)
        elif subject_id.startswith('5'):
            groups_rh['SCZ'].append(correlation_rh)
        elif subject_id.startswith('6'):
            groups_rh['BPLR'].append(correlation_rh)
        elif subject_id.startswith('7'):
            groups_rh['ADHD'].append(correlation_rh)

    overall_mean_lh = np.mean(correlations_lh)
    overall_mean_rh = np.mean(correlations_rh)
    group_means_lh = {group_lh: np.mean(corrs_lh) if corrs_lh else float('nan') for group_lh, corrs_lh in groups_lh.items()}
    group_means_rh = {group_rh: np.mean(corrs_rh) if corrs_rh else float('nan') for group_rh, corrs_rh in groups_rh.items()}

    return overall_mean_lh, overall_mean_rh, group_means_lh, group_means_rh

# Define the path pattern for CSV files
csv_pattern = os.path.join(os.getcwd(), 'derivatives', 'sub*', 'dwi', 'restored_full_association_matrix_sub-*_40seeds.csv')

# Find all CSV files matching the pattern
csv_files = glob.glob(csv_pattern)

# Compute mean correlations
overall_mean_lh, overall_mean_rh, group_means_lh, group_means_rh = process_files_and_compute_mean(csv_files)

# Save the results to a text file
output_file = "mean_spearman_correlations_aw40-rs_single_h.txt"

with open(output_file, 'w') as f:
    f.write(f"Overall Mean Spearman Correlation_lh: {overall_mean_lh}\n")
    for group_lh, mean_lh in group_means_lh.items():
        f.write(f"Mean Spearman Correlation for {group_lh}: {mean_lh}\n")
    f.write(f"\nOverall Mean Spearman Correlation_rh: {overall_mean_rh}\n")
    for group_rh, mean_rh in group_means_rh.items():
        f.write(f"Mean Spearman Correlation for {group_rh}: {mean_rh}\n")
print(f"Results saved to {output_file}")