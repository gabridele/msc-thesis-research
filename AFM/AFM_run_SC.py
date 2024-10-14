################################
# code to run AFM via structural connectivity
###############################

# import necessary libraries

import sys
import os
import re
import numpy as np
import pandas as pd
from scipy.stats import zscore, spearmanr, pearsonr
import matplotlib.pyplot as plt
from sklearn.metrics import r2_score, mean_absolute_error

def activity_flow_conn(conn_array, func_array):
    
    taskActMatrix = func_array # 3D shape parcel x timeseries x subj
    connMatrix = conn_array # 4D shape parcel x parcel x state x subj

    # define dimensions
    numTasks = taskActMatrix.shape[1]
    numRegions = taskActMatrix.shape[0]
    numConnStates = connMatrix.shape[2]
    numSubjs = connMatrix.shape[3]

    # Setup for prediction
    taskPredMatrix = np.zeros((numRegions, numTasks, numSubjs))
    taskActualMatrix = taskActMatrix
    regionNumList = np.arange(numRegions)

    # iterate through each subject
    for subjNum in range(numSubjs):
        # iterate thru each task
        for taskNum in range(numTasks):

            # Get this subject's activation pattern for this task
            taskActVect = taskActMatrix[:, taskNum, subjNum]

            # iterate thru each region
            for regionNum in range(numRegions):

                # Hold out region whose activity is being predicted
                otherRegions = np.delete(regionNumList, regionNum)

                # Get this region's connectivity pattern
                if numConnStates > 1:
                    stateFCVect = connMatrix[:, regionNum, taskNum, subjNum]
                else:
                    # If using resting-state (or any single state) data
                    stateFCVect = connMatrix[:, regionNum, 0, subjNum]

                # Calculate activity flow prediction
                taskPredMatrix[regionNum, taskNum, subjNum] = np.sum(taskActVect[otherRegions] * stateFCVect[otherRegions])
            
            ## Normalize values (z-score)
            taskPredMatrix[:, taskNum, subjNum] = zscore(taskPredMatrix[:, taskNum, subjNum])
            taskActualMatrix[:, taskNum, subjNum] = zscore(taskActMatrix[:, taskNum, subjNum])

    return taskPredMatrix

# the following 3 functions are used to restore the 'cleaned up' matrices to their original size, by reinserting the removed indices
def load_union_indices(subject, union_file):
    df = pd.read_excel(union_file)
    row = df.loc[df['subject'] == subject]
    if not row.empty:
        union_indices = row['union_indices'].values[0]
        if union_indices == '' or pd.isna(union_indices):
            return []
        return list(map(int, union_indices.split(', ')))
    else:
        raise ValueError(f"Subject {subject} not found in {union_file}.")

def restore_array(data: pd.DataFrame, cols_and_rows_to_insert: list[int]) -> pd.DataFrame:
    """
    Add use cases.

    Arguments:
        `data`: a pandas DataFrame, a square matrix
        `cols_and_rows_to_insert`: a list of integers, the indexes of the columns and rows to insert

    Returns:
        the dataframe with zero columns on the given indexes and zero rows on the given indexes.
    """
    # if data.shape[0] != data.shape[1]:
    #    raise ValueError("The input matrix should be squared")

    #for col_index in cols_and_rows_to_insert:
    #    adjusted_index = col_index
    #    data.insert(loc=adjusted_index, column=f"zero_col_{col_index}", value=0)

    for row_index in cols_and_rows_to_insert:
        adjusted_index = row_index
        zero_row = pd.DataFrame([[0] * data.shape[1]], columns=data.columns)
        data_top = data.iloc[:adjusted_index, :]
        data_bottom = data.iloc[adjusted_index:, :]
        data = pd.concat([data_top, zero_row, data_bottom], ignore_index=True)

    # This can be commented out if you are direclty saving the data to a file
    data.reset_index(drop=True, inplace=True)
    data.columns = range(data.shape[1])

    return data

def restore_task_matrix(subject, mod_task_file, union_file):
    union_indices = load_union_indices(subject, union_file)

    arraydf = pd.DataFrame(mod_task_file)

    restored_array = restore_array(arraydf, union_indices)

    return restored_array

# function to create scatter plots
def scatter_plot_func(p_array, e_array, spearman_corr, spearman_p_val, sub_id=None, save_dir=None):
    
    # make sure value is of float type
    spearman_corr = float(spearman_corr)
    spearman_p_val = float(spearman_p_val)
    
    pred_values = p_array
    actual_values = e_array

    plt.figure()
    plt.scatter(range(len(pred_values)), pred_values, color='lightblue', label='Predicted Activation')
    plt.scatter(range(len(actual_values)), actual_values, color='lightcoral', label='Empirical Activation')

    plt.title(f'Predicted vs Empirical Activation for {sub_id} - SC matrix based' if sub_id else f'Predicted vs Empirical Activation - SC matrix based')
    plt.xlabel('Region')
    plt.ylabel('Activation')

    plt.legend(
        loc='upper left',  # position inside the plot
        bbox_to_anchor=(1.05, 1),  # move legend outside the plot
        borderaxespad=0.,
        title=f"Spearman's $\\rho$: {spearman_corr:.3f} (p={spearman_p_val:.2g})"
    )
    if save_dir and sub_id:
        save_path = f"{save_dir}/scatter_plot_{sub_id}.png"
        plt.savefig(save_path, bbox_inches='tight')
        print(f"Plot saved to {save_path}")

    plt.show()
    
    return
    
def main(input_conn, input_func):
    
    base_name = os.path.basename(input_conn)
    # get sub ID
    sub_id = re.search(r'sub-\d+', base_name).group(0)
    # define file with indices to add back
    union_file = "nan_indices_with_union.xlsx"
    print(sub_id)

    # load matrices
    conn_array = pd.read_csv(input_conn, delimiter=',', header=None, dtype=float).to_numpy()
    func_array = np.load(input_func)

    # expand mtrx dimensions to fit AFM function
    func_array = np.expand_dims(func_array, axis=2)
    conn_array = np.expand_dims(conn_array, axis=2)
    conn_array = np.expand_dims(conn_array, axis=3)
    print('func shape', func_array.shape)
    print('conn shape', conn_array.shape)

    # run AFM
    taskPredMatrix = activity_flow_conn(conn_array, func_array)
    
    save_dir = f'derivatives/output_AFM_SC'

    # restore matrices to original shape
    restored_sc_matrix = restore_task_matrix(sub_id, taskPredMatrix[:, 0,], union_file)
    restored_func = restore_task_matrix(sub_id, func_array[:, 0,], union_file)

    os.makedirs(save_dir, exist_ok=True)
    restored_sc_matrix.to_csv(f"{save_dir}/restored_taskPredMatrix_{sub_id}_rs.csv", index=False, header=False)

    p_array = restored_sc_matrix.squeeze().to_numpy()
    e_array = restored_func.squeeze().to_numpy()

    print("p_array.shape", p_array.shape)
    print("e_array.shape", e_array.shape)
    
    # Compute metrics
    pearson_corr = pearsonr(p_array, e_array)
    spearman_corr, spearman_p_val = spearmanr(p_array, e_array)
    r2 = r2_score(e_array, p_array)
    mae = mean_absolute_error(e_array, p_array)
    
    # Save metrics in txt file
    metrics_path = os.path.join(save_dir, f"eval_metrics_{sub_id}_SC.txt")
    with open(metrics_path, 'w') as f:
        f.write(f"pearson_corr: {pearson_corr}\n")
        f.write(f"spearman_corr: {spearman_corr}, pvalue: {spearman_p_val}\n")
        f.write(f"R^2: {r2}\n")
        f.write(f"MAE: {mae}\n")
    
    # create scatter plot
    scatter_plot_func(p_array, e_array, spearman_corr, spearman_p_val, sub_id, save_dir)

if __name__ == "__main__":
    input_conn = sys.argv[1]
    input_func = sys.argv[2]

    main(input_conn, input_func)