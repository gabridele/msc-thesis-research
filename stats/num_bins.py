#!/usr/bin/env python3

import numpy as np
import argparse

def load_bins(bins_path):
    bins = np.load(bins_path, allow_pickle=True)
    return bins

def main():
    parser = argparse.ArgumentParser(description="Load bins and print the number of bins.")
    parser.add_argument("bins_path", type=str, help="Path to the bins file")
    args = parser.parse_args()

    bins = load_bins(args.bins_path)
    num_bins = len(bins)
    print("Number of Bins:", num_bins)

if __name__ == "__main__":
    main()