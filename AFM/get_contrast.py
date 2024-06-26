import sys
import os
import re
import numpy as np
import pandas as pd # type: ignore
import matplotlib.pyplot as plt # type: ignore
from scipy.stats import spearmanr, zscore, pearsonr # type: ignore
from sklearn.metrics import r2_score, mean_absolute_error # type: ignore

def avg_contrast(p_low_1500, p_low_3000, p_low_4500, p_high_1500, p_high_3000, p_high_4500, \
                 e_low_1500, e_low_3000, e_low_4500, e_high_1500, e_high_3000, e_high_4500):
    
    # load data
    p_low_1500 = np.load(p_low_1500)
    p_low_3000 = np.load(p_low_3000)
    p_low_4500 = np.load(p_low_4500)
    p_high_1500 = np.load(p_high_1500)
    p_high_3000 = np.load(p_high_3000)
    p_high_4500 = np.load(p_high_4500)
    e_low_1500 = np.load(e_low_1500)
    e_low_3000 = np.load(e_low_3000)
    e_low_4500 = np.load(e_low_4500)
    e_high_1500 = np.load(e_high_1500)
    e_high_3000 = np.load(e_high_3000)
    e_high_4500 = np.load(e_high_4500)
    
    ## PREDICTED MATRICES
    # normalize values
    p_low_1500 = zscore(p_low_1500)
    p_low_3000 = zscore(p_low_3000)
    p_low_4500 = zscore(p_low_4500)
    p_high_1500 = zscore(p_high_1500)
    p_high_3000 = zscore(p_high_3000)
    p_high_4500 = zscore(p_high_4500)

    # get avg across two main conditions
    p_low_avg = (p_low_1500 + p_low_3000 + p_low_4500) / 3
    p_high_avg = (p_high_1500 + p_high_3000 + p_high_4500) / 3

    # get contrast by computing low-high
    p_diff = p_high_avg - p_low_avg
    #slice to get only relevant dimension (for correlation purposes)
    p_diff = p_diff[:, 0, 0]
    p_diff = zscore(p_diff)

    ## EMPIRICAL MATRICES
    e_low_avg = (e_low_1500 + e_low_3000 + e_low_4500) / 3
    e_high_avg = (e_high_1500 + e_high_3000 + e_high_4500) / 3

    # get contrast by computing low-high
    e_diff = e_high_avg - e_low_avg
    #slice to get only relevant dimension (for correlation purposes)
    e_diff = e_diff[:, 0]
    e_diff = zscore(e_diff)
    
    # compute metrics
    pearson_corr = pearsonr(p_diff, e_diff)
    spearman_corr, spearman_p_val = spearmanr(p_diff, e_diff)
    r2 = r2_score(e_diff, p_diff)
    mae = mean_absolute_error(e_diff, p_diff)

    return p_diff, e_diff, pearson_corr, spearman_corr, spearman_p_val, r2, mae

def scatter_plot_func(p_diff, e_diff, spearman_corr, spearman_p_val, sub_id=None, save_dir=None):
    
    spearman_corr = float(spearman_corr)
    spearman_p_val = float(spearman_p_val)
    
    pred_values = p_diff
    actual_values = e_diff

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

def main(p_low_1500, p_low_3000, p_low_4500, p_high_1500, p_high_3000, p_high_4500, \
         e_low_1500, e_low_3000, e_low_4500, e_high_1500, e_high_3000, e_high_4500):
    
    base_name = os.path.basename(p_low_1500)
    sub_id = re.search(r'sub-\d+', os.path.basename(p_low_1500)).group(0)
    n_seeds = base_name.split('_low_wm_')[1].split('_')[1].split('.')[0]

    p_diff, e_diff, pearson_corr, spearman_corr, spearman_p_val, r2, mae = avg_contrast(p_low_1500, p_low_3000, p_low_4500, p_high_1500, p_high_3000, p_high_4500, \
                                                                                        e_low_1500, e_low_3000, e_low_4500, e_high_1500, e_high_3000, e_high_4500)

    os.makedirs(f'derivatives/output_AFM_{n_seeds}', exist_ok=True)
    save_dir = f"derivatives/output_AFM_{n_seeds}"

    metrics_path = os.path.join(save_dir, f"eval_metrics_{sub_id}_{n_seeds}.txt")

    # save metrics in txt file
    with open(metrics_path, 'w') as f:
        f.write(f"pearson_corr: {pearson_corr}\n")
        f.write(f"spearman_corr: {spearman_corr}\n")
        f.write(f"R^2: {r2}\n")
        f.write(f"MAE: {mae}\n")

    scatter_plot_func(p_diff, e_diff, spearman_corr, spearman_p_val, sub_id, save_dir)

if __name__ == "__main__":

    if len(sys.argv) != 13:
        print("##################### \
                \n Syntax error: Usage: python [this script.py] p_low_1500 p_low_3000 p_low_4500 p_high_1500 p_high_3000 p_high_4500 e_low_1500 e_low_3000 e_low_4500 e_high_1500 e_high_3000 e_high_4500 \
                \n (e = empirical, p = predicted)")
        sys.exit(1)
    
    main(*sys.argv[1:])