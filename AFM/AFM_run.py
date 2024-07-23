#### right code !!!!
import sys
import os
import numpy as np
import pandas as pd # type: ignore
from scipy.stats import zscore

def activity_flow_conn(conn_array, func_array):
    
    taskActMatrix = func_array #shape parcel x timeseries x subj
    connMatrix = conn_array # shape parcel x parcel x state x subj

    numTasks = taskActMatrix.shape[1]
    numRegions = taskActMatrix.shape[0]
    numConnStates = connMatrix.shape[2]
    numSubjs = connMatrix.shape[3]

    # Setup for prediction
    taskPredMatrix = np.zeros((numRegions, numTasks, numSubjs))
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
            
            ## Normalize values (z-score)
            taskPredMatrix[:, taskNum, subjNum] = zscore(taskPredMatrix[:, taskNum, subjNum])
            taskActualMatrix[:, taskNum, subjNum] = zscore(taskActMatrix[:, taskNum, subjNum])

    return taskPredMatrix

def main(input_conn, input_func, n_seeds):

    sub_id = input_conn.split('/')[-3]
    print(sub_id)

    #base_name = os.path.basename(input_func)
    #condition = base_name.split('_sub')[0]

    conn_array = pd.read_csv(input_conn, delimiter=',', header=None, dtype=float).to_numpy()
    func_array = np.load(input_func)

    func_array = np.expand_dims(func_array, axis=1)
    func_array = np.expand_dims(func_array, axis=2)

    conn_array = np.expand_dims(conn_array, axis=2)
    conn_array = np.expand_dims(conn_array, axis=3)
    
    taskPredMatrix = activity_flow_conn(conn_array, func_array)
    
    os.makedirs(f'derivatives/preproc_dl/output_AFM_{n_seeds}', exist_ok=True)

    save_dir = f"derivatives/preproc_dl/output_AFM_{n_seeds}"
    os.makedirs(save_dir, exist_ok=True)

    task_pred_matrix_path = os.path.join(save_dir, f"taskPredMatrix_{sub_id}_{n_seeds}.npy")
    np.save(task_pred_matrix_path, taskPredMatrix)


if __name__ == "__main__":

    input_conn = sys.argv[1]
    input_func = sys.argv[2]
    n_seeds = sys.argv[3] # to put right name when saving

    main(input_conn, input_func, n_seeds)
