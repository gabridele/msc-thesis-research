#!/usr/bin/env python3

import numpy as np
import argparse
import pickle
from collections import defaultdict
from multiprocessing import Pool, cpu_count

def extract_edges(stacked_matrices):
    n, _, num_subjects = stacked_matrices.shape
    combined_edges = defaultdict(list)
    for k in range(num_subjects):
        for i in range(n):
            for j in range(i + 1, n):
                if stacked_matrices[i, j, k] > 0:
                    combined_edges[(i, j)].append(stacked_matrices[i, j, k])
    return combined_edges

def calculate_percentiles(all_lengths, M):
    return np.percentile(all_lengths, np.linspace(0, 100, M + 1))

def define_bins(combined_edges):
    all_lengths = [length for lengths in combined_edges.values() for length in lengths]
    M = len(all_lengths)  # Total number of edges in the consensus network

    percentiles = calculate_percentiles(all_lengths, M)

    bins = [(percentiles[i], percentiles[i + 1]) for i in range(len(percentiles) - 1)]
    return bins

def main():
    parser = argparse.ArgumentParser(description="Process stacked adjacency matrices.")
    parser.add_argument("input_path", type=str, help="Path to the .npy file containing stacked adjacency matrices")
    parser.add_argument("output_combined_edges", type=str, help="Path to save the combined edges file")
    parser.add_argument("output_bins", type=str, help="Path to save the bins file")
    args = parser.parse_args()

    # Load the 3D array from the .npy file
    stacked_matrices = np.load(args.input_path)

    combined_edges = extract_edges(stacked_matrices)
    bins = define_bins(combined_edges)

    # Save combined edges using pickle
    with open(args.output_combined_edges, 'wb') as f:
        pickle.dump(combined_edges, f)

    # Save bins using numpy
    np.save(args.output_bins, bins)

    print("Combined Edges and Bins have been saved.")

if __name__ == "__main__":
    main()