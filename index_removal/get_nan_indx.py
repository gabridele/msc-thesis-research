# code to find ROIs with fewer than 5 connections and with no connections for SC matrix
# find nan values in FC matrix
# then nan indices are saved into xlsx

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
    low_non_zero_indices = df.index[df.apply(lambda row: (row != 0).sum() < 5, axis=1)].tolist()
    # Combine indices and remove duplicates
    all_indices = list(set(zero_row_indices + low_non_zero_indices))
    count = len(all_indices)
    
    return count, all_indices

def process_npy(file_path):
    # Load the .npy file
    data = np.load(file_path)
    
    # Check if data is a 2D array
    if len(data.shape) != 2:
        raise ValueError("The NPY file does not contain a 2D array.")
    
    # Convert to DataFrame
    df = pd.DataFrame(data)
    
    # Identify NaN positions
    nan_positions = df.isna()
    
    # Count the number of unique columns containing at least one NaN
    unique_nan_columns = nan_positions.any(axis=0).sum()
    
    # Extract the indices of NaNs (row, column format)
    nan_indices = np.argwhere(nan_positions.to_numpy())
 
    # Prepare formatted output of the indices
    formatted_nan_positions = [f"Row {row}, Column {col}" for row, col in nan_indices]
    
    return unique_nan_columns, formatted_nan_positions
    
# Prepare data for CSV
data = []

# Use glob to find all relevant dwi and rs files
file_paths_dwi = glob.glob("derivatives/**/dwi/sub*_Schaefer2018_400Parcels_Tian_Subcortex_S4_1mm_5000000mio_connectome.csv", recursive=True)
file_paths_rs = glob.glob("derivatives/**/func/*_rs_correlation_matrix.npy", recursive=True)

print(f"Found {len(file_paths_dwi)} CSV files and {len(file_paths_rs)} NPY files")

def extract_row_0_columns(fc_nan_count, nan_positions, target_row=0):
    # Check if the fc_nan_count matches 454
    if fc_nan_count == 454:
        # Extract column indices for NaNs in the target row (default: row 0)
        row_0_columns = []
        
        # Loop through the list of formatted NaN positions
        for position in nan_positions:
            # Split the string to get the row and column
            row, col = position.split(", ")
            row_num = int(row.split()[1])  # Extract the row number
            col_num = int(col.split()[1])  # Extract the column number
            
            # Check if the row is the target row (0 by default)
            if row_num == target_row:
                row_0_columns.append(col_num)
        
        # Check if row_0_columns contain all numbers from 0 to 453
        if row_0_columns == list(range(454)):
            return "0"
        
        # Return the list of column indices if condition is not met
        return row_0_columns
    
    else:
        return []  # Return an empty list if fc_nan_count is not 454


# Process files
for file_path_dwi in file_paths_dwi:
    
    subject_id = extract_subject_id(file_path_dwi)
    # print(subject_id)
    dwi_count, dwi_indices = process_csv(file_path_dwi)  
    
    # Find corresponding z file path using the same subject_id
    file_path_rs = f"derivatives/{subject_id}/func/{subject_id}_rs_correlation_matrix.npy"
    
    print(file_path_rs)
    
    if os.path.exists(file_path_rs):
        fc_nan_count, formatted_nan_positions = process_npy(file_path_rs)
        
        # extract_row_0_columns to get the NaN columns in row 0
        row_0_columns = extract_row_0_columns(fc_nan_count, formatted_nan_positions)
        
        # Update fc_nan_count and formatted_nan_positions
        if row_0_columns == "0":
            fc_nan_count = 0
            formatted_nan_positions = "0"
        else:
            fc_nan_count = len(row_0_columns)  # Number of NaN values in row 0
            formatted_nan_positions = ', '.join(map(str, row_0_columns))  # Columns with NaNs in row 0
    
    else:
        print(f"File not found: {file_path_rs}")
        formatted_nan_positions = 'file not found'
        fc_nan_count = 0

    # Prepare formatted data for output
    formatted_dwi_indices = ', '.join(map(str, dwi_indices))
    
    # Append data for the current subject
    data.append([subject_id, dwi_count, formatted_dwi_indices, fc_nan_count, formatted_nan_positions])

# Sort data by subject ID
data.sort(key=lambda x: x[0])

# Create a DataFrame and save to Excel
df = pd.DataFrame(data, columns=['subject', 'dwi_count', 'dwi_indices', 'fc_nan_count', 'fc_nan_indices'])

# Save to Excel
df.to_excel('nan_indices.xlsx', index=False)

df = pd.read_excel('nan_indices.xlsx')

print(df.head())