import argparse
import numpy as np

def num_bins(data):
    """
    Determine the number of bins heuristically as the square root of the mean binary density across participants.
    
    Parameters:
    data (numpy.ndarray): An n x n x subjects array.
    
    Returns:
    int: The number of bins.
    """
    N = data.shape[0]

    # Convert adjacency matrices to binary (nonzero values become 1)
    binary_data = (data != 0).astype(int)

    # Compute binary density for each participant
    total_possible_connections = N * (N - 1)  # Exclude self-connections
    binary_densities = binary_data.sum(axis=(0, 1)) / total_possible_connections

    # Compute the mean binary density
    mean_binary_density = np.mean(binary_densities)

    # Compute the number of bins as the square root of the mean binary density
    num_bins = int(np.sqrt(mean_binary_density))

    return num_bins

# Example usage
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Get number of bins.")
    parser.add_argument("input_path", type=str, help="Path to the .npy file containing the data")
    args = parser.parse_args()
    data = np.load(args.input_path)
    bins = num_bins(data)
    print(f"Mean Binary Density: {np.mean((data != 0).astype(int).sum(axis=(0, 1)) / (data.shape[0] * (data.shape[0] - 1)))}")
    print(f"Number of bins: {bins}")