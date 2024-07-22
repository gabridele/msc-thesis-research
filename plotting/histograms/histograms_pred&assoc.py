#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: gabrieledele
"""
import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
import matplotlib.pyplot as plt
from scipy.stats import zscore

class HistogramPlotterMtrx:
    def __init__(self, array1, array2, array3):
        self.array1 = self.extract_upper_triangular(array1)
        self.array2 = self.extract_upper_triangular(array2)
        self.array3 = self.extract_upper_triangular(array3)

    def extract_upper_triangular(self, array):
        # Get the upper triangular indices
        upper_tri_indices = np.triu_indices(array.shape[0], k=1)  # k=1 to exclude the diagonal
        # Extract the values at these indices and flatten them
        upper_triangular_flat = array[upper_tri_indices]
        return upper_triangular_flat

    def plot_histograms(self):
        # Create a figure and subplots
        fig, axes = plt.subplots(3, 1, figsize=(10, 15))

        # Plot histograms
        self._plot_single_histogram(axes[0], self.array1, 'Histogram of raw data')
        self._plot_single_histogram(axes[1], self.array2, 'Histogram of scaled data')
        self._plot_single_histogram(axes[2], self.array3, 'Histogram of scaled and norm\'d data' )

        fig.suptitle('Histograms of association matrix', fontsize=16)
        
        # Adjust layout
        plt.subplots_adjust(hspace=0.4, top=0.93)  # Adjust top to fit the suptitle
        # Show plot
        plt.show()


    def _plot_single_histogram(self, ax, data, title):
        # Plot histogram with density=True for relative frequency
        counts, bins, patches = ax.hist(data, bins='auto', density=True, color='skyblue')
        
        # Set the title and labels
        ax.set_title(title, fontsize=12)
        ax.set_xlabel('Value', fontsize=10)
        ax.set_ylabel('Relative Frequency', fontsize=10)
        
        # Set y-axis limits and intervals for relative frequency
        ax.set_ylim(0, 1)
        ax.set_yticks(np.arange(0, 1.1, 0.1))

class HistogramPlotter:
    def __init__(self, array1, array2, array3):
        self.array1 = array1
        self.array2 = array2
        self.array3 = array3

    def plot_histograms(self):
        # Create a figure and subplots
        fig, axes = plt.subplots(3, 1, figsize=(10, 15))

        # Plot histograms
        self._plot_single_histogram(axes[0], self.array1, 'Histogram of raw data')
        self._plot_single_histogram(axes[1], self.array2, 'Histogram of scaled data')
        self._plot_single_histogram(axes[2], self.array3, 'Histogram of scaled and norm\'d data' )

        # Add an overall title to the figure
        fig.suptitle('Histogram of predicted activations', fontsize=16)
        
        # Adjust layout
        plt.subplots_adjust(hspace=0.4, top=0.93)  # Adjust top to fit the suptitle
        # Show plot
        plt.show()

    def _plot_single_histogram(self, ax, data, title):
        # Plot histogram with density=True for relative frequency
        counts, bins, patches = ax.hist(data, bins='auto', density=True, edgecolor='black', color='skyblue')
        
        # Set the title and labels
        ax.set_title(title, fontsize=12)
        ax.set_xlabel('Value', fontsize=10)
        ax.set_ylabel('Relative Frequency', fontsize=10)
        
        # Set y-axis limits and intervals for relative frequency
        ax.set_ylim(0, 0.005)
        ax.set_yticks(np.arange(0, 0.005, 0.001))
        
# load mtrx           
full_assoc = "/Users/gabrieledele/.anydesk/incoming/2024-06-26 10:56:18.334/full_association_mtrix_sub-10339_30seeds.csv"
full_assoc = pd.read_csv(full_assoc, sep=',', header=None).to_numpy(dtype=float)

# scale mtrx
scaler = MinMaxScaler(feature_range=(-1,1))
scaler.fit(full_assoc)
full_scaled = scaler.transform(full_assoc)
# get z-score
z_assoc = zscore(full_scaled)

#plot it
plotter = HistogramPlotterMtrx(full_assoc, full_scaled, z_assoc)
plotter.plot_histograms()

#load data
raw_diff = np.load("/Users/gabrieledele/Desktop/GitHub/thesis-work/AFM/derivatives/output_AFM_30/raw_diff.npy")
diff_scaled = np.load("/Users/gabrieledele/Desktop/GitHub/thesis-work/AFM/derivatives/output_AFM_30/raw_diff_resc.npy")            
diff_scaled_z = np.load("/Users/gabrieledele/Desktop/GitHub/thesis-work/AFM/derivatives/output_AFM_30/raw_diff_resc_z.npy")            

#plot it
plotter = HistogramPlotter(raw_diff, diff_scaled, diff_scaled_z)
plotter.plot_histograms()         















