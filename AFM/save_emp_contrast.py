import sys
import os
import re
import numpy as np
import pandas as pd # type: ignore
import matplotlib.pyplot as plt # type: ignore
from scipy.stats import spearmanr, zscore, pearsonr # type: ignore
from sklearn.metrics import r2_score, mean_absolute_error # type: ignore

def avg_contrast(e_low_1500, e_low_3000, e_low_4500, e_high_1500, e_high_3000, e_high_4500):
    
    # load data

    e_low_1500 = np.load(e_low_1500)
    e_low_3000 = np.load(e_low_3000)
    e_low_4500 = np.load(e_low_4500)
    e_high_1500 = np.load(e_high_1500)
    e_high_3000 = np.load(e_high_3000)
    e_high_4500 = np.load(e_high_4500)
    
   
    ## EMPIRICAL MATRICES
    e_low_avg = (e_low_1500 + e_low_3000 + e_low_4500) / 3
    e_high_avg = (e_high_1500 + e_high_3000 + e_high_4500) / 3

    # get contrast by computing low-high
    e_diff = e_high_avg - e_low_avg
    
    #slice to get only relevant dimension (for correlation purposes)
    e_diff = e_diff[:, 0]
    

    return e_diff


def main(e_low_1500, e_low_3000, e_low_4500, e_high_1500, e_high_3000, e_high_4500):
    
    base_name = os.path.basename(e_low_1500)
    sub_id = re.search(r'sub-\d+', os.path.basename(e_low_1500)).group(0)

    e_diff = avg_contrast(e_low_1500, e_low_3000, e_low_4500, e_high_1500, e_high_3000, e_high_4500)

    save_contrast = f"derivatives/{sub_id}/func/"
    
    e_diff_path = os.path.join(save_contrast, f"emp_contrast_{sub_id}.npy")
    np.save(e_diff_path, e_diff)
    
if __name__ == "__main__":

    if len(sys.argv) != 7:
        print("##################### \
                \n Syntax error: Usage: python [this script.py] e_low_1500 e_low_3000 e_low_4500 e_high_1500 e_high_3000 e_high_4500 \
                \n (e = empirical)")
        sys.exit(1)
    
    main(*sys.argv[1:])
