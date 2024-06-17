#### right code !!!!
import sys
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import spearmanr


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
            taskPredMatrix[:, taskNum, subjNum] = (taskPredMatrix[:, taskNum, subjNum] - np.mean(taskPredMatrix[:, taskNum, subjNum])) / np.std(taskPredMatrix[:, taskNum, subjNum])
            taskActualMatrix[:, taskNum, subjNum] = (taskActMatrix[:, taskNum, subjNum] - np.mean(taskActMatrix[:, taskNum, subjNum])) / np.std(taskActMatrix[:, taskNum, subjNum])

            # Calculate predicted to actual similarity for this task
            pearson_corr = np.corrcoef(taskPredMatrix[:, taskNum, subjNum], taskActualMatrix[:, taskNum, subjNum])[0]
            spearman_corr = spearmanr(taskPredMatrix[:, taskNum, 0], taskActualMatrix[:, taskNum, 0])[0]
        #taskPredRs[taskNum, subjNum] = pearson_corr[0, 1]
    
    return taskPredMatrix, taskActualMatrix, pearson_corr, spearman_corr
    
def scatter_plot_func(taskPredMatrix, taskActualMatrix, pearson_corr, spearman_corr, sub_id=None, save_dir=None):
    pred_values = taskPredMatrix[:, 0, 0]
    actual_values = taskActualMatrix[:, 0, 0]

    plt.figure()
    plt.scatter(range(len(pred_values)), pred_values, color='blue', label='Predicted Activation')
    plt.scatter(range(len(actual_values)), actual_values, color='red', label='Actual Activation')

    plt.title(f'Predicted vs Actual Activation for {sub_id}' if sub_id else 'Predicted vs Actual Activation')
    plt.xlabel('Region')
    plt.ylabel('Activation')

    # Add correlation values to the legend
    plt.legend(
        loc='upper right',
        title=f"Pearson: {pearson_corr:.2f}, Spearman: {spearman_corr:.2f}",
    )

    if save_dir and sub_id:
        save_path = f"{save_dir}/scatter_plot_{sub_id}.png"
        plt.savefig(save_path)
        print(f"Plot saved to {save_path}")

    plt.show()
    
    return

def main(input_conn, input_func):

    sub_id = input_conn.split('/')[-3]
    print(sub_id)

    conn_array = np.loadtxt(input_conn, delimiter=",", dtype=float)
    func_array = np.load(input_func)

    func_array = np.expand_dims(func_array, axis=1)
    func_array = np.expand_dims(func_array, axis=2)

    conn_array = np.expand_dims(conn_array, axis=2)
    conn_array = np.expand_dims(conn_array, axis=3)


    taskPredMatrix, taskActualMatrix, pearson_corr, spearman_corr = activity_flow_conn(conn_array, func_array)
    
    correlations_path = f"derivatives/output_sample_AFM/correlations_{sub_id}.txt"

    # Open the file in write mode
    with open(correlations_path, 'w') as f:
        # Write the variables to the file
        f.write(f"pearson_corr: {pearson_corr}\n")
        f.write(f"spearman_corr: {spearman_corr}\n")

    save_dir = "derivatives/output_sample_AFM/"
    scatter_plot = scatter_plot_func(taskPredMatrix, taskActualMatrix, sub_id, save_dir)

if __name__ == "__main__":

    input_conn = sys.argv[1]
    input_func = sys.argv[2]
    
    main(input_conn, input_func)
