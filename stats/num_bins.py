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
    # Binarize the data
    binary_data = (data > 0).astype(int)
    
    # Calculate the mean binary density across participants
    mean_density = np.mean(binary_data)
    
    # Determine the number of bins
    num_bins = int(np.sqrt(mean_density))
    
    return num_bins

# Example usage
if __name__ == "__main__":
    # Example data: 3x3x2 array
    parser = argparse.ArgumentParser(description="Get number of bins.")
    parser.add_argument("input_path", type=str, help="Path to the .npy file containing the data")
    args = parser.parse_args()
    data = np.load(args.input_path)
    bins = num_bins(data)
    print(f"Number of bins: {bins}")