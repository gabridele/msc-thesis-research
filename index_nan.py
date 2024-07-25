import os
import re
import numpy as np
import pandas as pd
import glob

# Function to extract subject ID from file path
def extract_subject_id(file_path):
    match = re.search(r'sub-\d+', file_path)
    if match:
        return match.group(0)
    return None

# Function to count zero rows and rows with 5 or fewer non-zero values and record their indices from a CSV file
def process_csv(file_path):
    df = pd.read_csv(file_path, header=None)
    # Rows with all zero values
    zero_row_indices = df.index[(df == 0).all(axis=1)].tolist()
    # Rows with 5 or fewer non-zero values
    low_non_zero_indices = df.index[df.apply(lambda row: (row != 0).sum() <= 5, axis=1)].tolist()
    # Combine indices and remove duplicates
    all_indices = list(set(zero_row_indices + low_non_zero_indices))
    count = len(all_indices)
    
    # Debug print statements
    print(f"Processing CSV: {file_path}")
    print(f"Zero row indices: {zero_row_indices}")
    print(f"Low non-zero indices: {low_non_zero_indices}")
    print(f"Total count: {count}, All indices: {all_indices}")
    
    return count, all_indices

# Function to count NaN rows and record indices from an NPY file
def process_npy(file_path):
    data = np.load(file_path)
    # Convert to DataFrame
    df = pd.DataFrame(data)

    
    # Detect nans
    nan_row_indices = df.index[df.isna().any(axis=1)].tolist()
    # Detect rows with all zero values
    zero_row_indices = df.index[(df == 0).all(axis=1)].tolist()
    
    return nan_row_indices, zero_row_indices

# Prepare data for CSV
data = []

# Use glob to find all relevant y and z files
file_paths_y = glob.glob("derivatives/**/dwi/*_Schaefer2018_400Parcels_Tian_Subcortex_S4_1mm_5000000mio_connectome.csv", recursive=True)
file_paths_z = glob.glob("derivatives/**/func/*_rs_correlation_matrix.npy", recursive=True)

print(f"Found {len(file_paths_y)} CSV files and {len(file_paths_z)} NPY files")

# Process files
for file_path_y in file_paths_y:
    subject_id = extract_subject_id(file_path_y)
    dwi_count, dwi_indices = process_csv(file_path_y)
    
    # Find corresponding z file path using the same subject_id
    file_path_z = next((path for path in file_paths_z if subject_id in path), None)
    if file_path_z:
        nan_row_indices, zero_row_indices = process_npy(file_path_z)
        fc_nan_count = len(nan_row_indices)
    else:
        fc_nan_count, nan_row_indices = 0, []
        zero_row_indices = []

    data.append([subject_id, dwi_count, dwi_indices, fc_nan_count, nan_row_indices, zero_row_indices])

    # Debug print statement
    print(f"Subject ID: {subject_id}")
    print(f"DWI count: {dwi_count}, DWI indices: {dwi_indices}")
    print(f"FC NaN count: {fc_nan_count}, FC NaN indices: {nan_row_indices}")
    print(f"FC Zero indices: {zero_row_indices}")

# Sort data by subject ID
data.sort(key=lambda x: x[0])

# Create a DataFrame and save to Excel
df = pd.DataFrame(data, columns=['subject', 'dwi_count', 'dwi_indices', 'fc_nan_count', 'fc_nan_indices', 'fc_zero_indices'])
df.to_excel('output.xlsx', index=False)