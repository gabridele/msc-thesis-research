import sys
import os
import re
import numpy as np
import pandas as pd # type: ignore
import matplotlib.pyplot as plt # type: ignore
from scipy.stats import spearmanr, zscore, pearsonr # type: ignore
from sklearn.metrics import r2_score, mean_absolute_error # type: ignore

def avg_contrast(p_array, e_array):
    
    # load data
    p_array = np.load(p_array)
    e_array = np.load(e_array)

    
    p_array = p_array[:, 0, 0]
    e_array = e_array[:, 0] 
    print("p_array.shape", p_array.shape)
    print("e_array.shape", e_array.shape)
    
    # compute metrics
    pearson_corr = pearsonr(p_array, e_array)
    spearman_corr, spearman_p_val = spearmanr(p_array, e_array)
    r2 = r2_score(e_array, p_array)
    mae = mean_absolute_error(e_array, p_array)

    return p_array, e_array, pearson_corr, spearman_corr, spearman_p_val, r2, mae

def scatter_plot_func(p_array, e_array, spearman_corr, spearman_p_val, sub_id=None, save_dir=None):
    
    # make sure value is of float type
    spearman_corr = float(spearman_corr)
    spearman_p_val = float(spearman_p_val)
    
    pred_values = p_array
    actual_values = e_array

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

def main(p_array, e_array):
    
    base_name = os.path.basename(p_array)
    sub_id = re.search(r'sub-\d+', os.path.basename(p_array)).group(0)
    n_seeds = base_name.split('_')[2].split('.')[0]

    p_array, e_array, pearson_corr, spearman_corr, spearman_p_val, r2, mae = avg_contrast(p_array, e_array)

    os.makedirs(f'derivatives/preproc_dl/output_AFM_{n_seeds}', exist_ok=True)
    save_dir = f"derivatives/preproc_dl/output_AFM_{n_seeds}"

    metrics_path = os.path.join(save_dir, f"eval_metrics_{sub_id}_{n_seeds}.txt")

    # save metrics in txt file
    with open(metrics_path, 'w') as f:
        f.write(f"pearson_corr: {pearson_corr}\n")
        f.write(f"spearman_corr: {spearman_corr}\n")
        f.write(f"R^2: {r2}\n")
        f.write(f"MAE: {mae}\n")

    scatter_plot_func(p_array, e_array, spearman_corr, spearman_p_val, sub_id, save_dir)

if __name__ == "__main__":

    if len(sys.argv) != 3:
        print("##################### \
                \n Syntax error: Usage: python [this script.py] p_array e_array \
                \n (e = empirical, p = predicted)")
        sys.exit(1)
    
    main(*sys.argv[1:])
