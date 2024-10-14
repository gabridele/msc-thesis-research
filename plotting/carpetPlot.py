#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Dec  6 15:10:16 2022

@author: ludovicocoletta
"""
import os
import re
import glob
import matplotlib.pyplot as plt
from nilearn.plotting import plot_carpet
import nibabel as nib
import numpy as np

def main():
    path_to_ts = sorted(glob.glob('derivatives/sub*/func/sub*_regressed_smoothed.nii.gz'))
    t_r = 2
    
    for iii in path_to_ts:
        print('now processing:', iii)
        image_4d = nib.load(iii)
        
        match = re.search(r"sub-\d+", iii)
        sub_string = match.group(0) if match else None

        # Construct the mask file path
        func_dir = os.path.dirname(iii)
        subject_dir = os.path.dirname(func_dir)
        mask_pattern = os.path.join(subject_dir, 'func', '*task-rest_bold_space-MNI152NLin2009cAsym_brainmask.nii.gz')
        mask_file = glob.glob(mask_pattern)
        
        if not mask_file:
            print(f"Mask file not found for {iii}")
            continue
        
        mask_image = nib.load(mask_file[0])

        # Construct FD file path
        fd_file = os.path.join(subject_dir, 'func/', sub_string + '_task-rest_FD.txt')

        if not os.path.isfile(fd_file):
            print(f"FD file not found: {fd_file}")
            continue

        # Create the figure and plot
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(20, 10), sharex=True, gridspec_kw={'height_ratios': [1, 4]})
        
        # Plot FD data
        ax1.plot(np.loadtxt(fd_file))
        ax1.set_ylabel('FD', fontsize=28)  # Set the label size equal to tick label size
        ax1.set_ylim((0., 0.7))
        
        # Set larger tick labels for ax1
        ax1.tick_params(axis='both', which='major', labelsize=22)  # Increase major tick label size
        ax1.tick_params(axis='both', which='minor', labelsize=22)

        # Plot the carpet plot
        plot_carpet(image_4d, mask_image, t_r=t_r, detrend=False, figure=fig, axes=ax2)
        # Set larger tick labels for ax2 (carpet plot)
        ax2.tick_params(axis='both', which='major', labelsize=22)  # Increase major tick label size
        ax2.tick_params(axis='both', which='minor', labelsize=22)  # Increase minor tick label size

        # Set axis labels (if needed)
        ax2.set_xlabel('Timepoints', fontsize=28)  # Set the label size equal to tick label size
        ax2.set_ylabel('Voxels', fontsize=28)

        fig.suptitle(f'Carpet plot for resting-state fMRI data - {sub_string}', fontsize=14)
        plt.savefig('rs_QC/' + sub_string + '_qc_rs.png')
        plt.close('all')

if __name__ == "__main__":
    main()   
