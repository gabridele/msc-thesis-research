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
    
    return count, all_indices

# Function to count NaN rows and record indices from an NPY file
def process_npy(file_path):
    data = np.load(file_path)
    
    # Check if data is a 2D array
    if len(data.shape) != 2:
        raise ValueError("The NPY file does not contain a 2D array.")
    
    # Convert to DataFrame
    df = pd.DataFrame(data)
    
    # Detect rows with NaNs
    nan_positions = {}
    for index, row in df.iterrows():
        nan_cols = [col for col in df.columns if pd.isna(row[col])]
        if nan_cols:
            nan_positions[index] = nan_cols
    
    # Count NaN rows
    fc_nan_count = len(nan_positions)
    
    # Prepare formatted NaN positions for output
    formatted_nan_positions = {index: ', '.join(map(str, cols)) for index, cols in nan_positions.items()}
    
    return fc_nan_count, formatted_nan_positions

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
    file_path_z = f"derivatives/{subject_id}/func/{subject_id}_rs_correlation_matrix.npy"
    if os.path.exists(file_path_z):
        fc_nan_count, formatted_nan_positions = process_npy(file_path_z)
    else:
        print(f"File not found: {file_path_z}")
        formatted_nan_positions = {}
        fc_nan_count = 0

    # Prepare formatted data for output
    formatted_dwi_indices = ', '.join(map(str, dwi_indices))
    formatted_nan_positions_str = '; '.join([f"Row {key}: Columns {value}" for key, value in formatted_nan_positions.items()])
    
    data.append([subject_id, dwi_count, formatted_dwi_indices, fc_nan_count, formatted_nan_positions_str])

# Sort data by subject ID
data.sort(key=lambda x: x[0])

# Create a DataFrame and save to Excel
df = pd.DataFrame(data, columns=['subject', 'dwi_count', 'dwi_indices', 'fc_nan_count', 'fc_nan_indices'])

# Save to Excel
df.to_excel('output.xlsx', index=False)