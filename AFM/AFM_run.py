#### right code !!!!
import sys
import os
import numpy as np
import pandas as pd # type: ignore
import matplotlib.pyplot as plt # type: ignore
from scipy.stats import spearmanr, zscore, pearsonr # type: ignore
from sklearn.metrics import r2_score, mean_absolute_error # type: ignore

def activity_flow_conn(conn_array, func_array):
    
    taskActMatrix = func_array #shape parcel x timeseries x subj
    connMatrix = conn_array # shape parcel x parcel x state x subj

    numTasks = taskActMatrix.shape[1]
    numRegions = taskActMatrix.shape[0]
    numConnStates = connMatrix.shape[2]
    numSubjs = connMatrix.shape[3]

    # Setup for prediction
    taskPredMatrix = np.zeros((numRegions, numTasks, numSubjs))
    taskPredRs = np.zeros((numTasks, numSubjs))
    taskActualMatrix = taskActMatrix
    regionNumList = np.arange(numRegions)

    for subjNum in range(numSubjs):
        for taskNum in range(numTasks):

            # Get this subject's activation pattern for this task
            taskActVect = taskActMatrix[:, taskNum, subjNum]

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
            # Normalize values (z-score)
            taskPredMatrix[:, taskNum, subjNum] = zscore(taskPredMatrix[:, taskNum, subjNum])
            taskActualMatrix[:, taskNum, subjNum] = zscore(taskActMatrix[:, taskNum, subjNum])

            # get metrics
            pearson_corr = pearsonr(taskPredMatrix[:, taskNum, subjNum], taskActualMatrix[:, taskNum, subjNum])
            spearman_corr, spearman_p_val = spearmanr(taskPredMatrix[:, taskNum, 0], taskActualMatrix[:, taskNum, 0])
            r2 = r2_score(taskActualMatrix[:, taskNum, subjNum], taskPredMatrix[:, taskNum, subjNum])
            mae = mean_absolute_error(taskActualMatrix[:, taskNum, subjNum], taskPredMatrix[:, taskNum, subjNum])       
        
        #taskPredRs[taskNum, subjNum] = pearson_corr[0, 1]
    
    return taskPredMatrix, taskActualMatrix, pearson_corr, spearman_corr, spearman_p_val, r2, mae
    
def scatter_plot_func(taskPredMatrix, taskActualMatrix, spearman_corr, spearman_p_val, sub_id=None, save_dir=None):
    
    spearman_corr = float(spearman_corr)
    spearman_p_val = float(spearman_p_val)
    
    pred_values = taskPredMatrix[:, 0, 0]
    actual_values = taskActualMatrix[:, 0, 0]

    plt.figure()
    plt.scatter(range(len(pred_values)), pred_values, color='lightblue', label='Predicted Activation')
    plt.scatter(range(len(actual_values)), actual_values, color='lightcoral', label='Empirical Activation')

    plt.title(f'Predicted vs Empirical Activation for {sub_id}' if sub_id else 'Predicted vs Empirical Activation')
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

def main(input_conn, input_func, n_seeds):

    sub_id = input_conn.split('/')[-3]
    print(sub_id)

    base_name = os.path.basename(input_func)
    condition = base_name.split('_sub')[0]

    conn_array = pd.read_csv(input_conn, delimiter=',', header=None, dtype=float).to_numpy()
    func_array = np.load(input_func)

    func_array = np.expand_dims(func_array, axis=1)
    func_array = np.expand_dims(func_array, axis=2)

    conn_array = np.expand_dims(conn_array, axis=2)
    conn_array = np.expand_dims(conn_array, axis=3)


    taskPredMatrix, taskActualMatrix, pearson_corr, spearman_corr, spearman_p_val, r2, mae = activity_flow_conn(conn_array, func_array)
    
    os.makedirs(f'derivatives/output_AFM_{condition}_{n_seeds}', exist_ok=True)
    
    metrics_path = f"derivatives/output_AFM_{condition}_{n_seeds}/eval_metrics_{sub_id}_{n_seeds}.txt"

    # Open the file in write mode
    with open(metrics_path, 'w') as f:
        # Write the variables to the file
        f.write(f"pearson_corr: {pearson_corr}\n")
        f.write(f"spearman_corr: {spearman_corr}\n")
        f.write(f"R^2: {r2}\n")
        f.write(f"MAE: {mae}\n")

    save_dir = f"derivatives/output_AFM_{condition}_{n_seeds}"

    task_pred_matrix_path = os.path.join(save_dir, f"taskPredMatrix_{sub_id}_{condition}_{n_seeds}.npy")
    np.save(task_pred_matrix_path, taskPredMatrix)
    
    print(taskPredMatrix.shape)
    
    scatter_plot_func(taskPredMatrix, taskActualMatrix, spearman_corr, spearman_p_val, sub_id, save_dir)

if __name__ == "__main__":

    input_conn = sys.argv[1]
    input_func = sys.argv[2]
    n_seeds = sys.argv[3] # to put right name when saving

    main(input_conn, input_func, n_seeds)
