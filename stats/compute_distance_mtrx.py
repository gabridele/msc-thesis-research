import numpy as np
from scipy.spatial.distance import cdist
import pandas as pd

def compute_distance_matrix(coordinates):
    """
    Compute the distance matrix for a given set of coordinates.
    
    :param coordinates: [node x 3] array of (x, y, z) coordinates
    :return: [node x node] distance matrix
    """
    dist_matrix = cdist(coordinates, coordinates, metric='euclidean')
    return dist_matrix

# Step 1: Load the coordinates from a CSV file
def load_coordinates(csv_path):
    """
    Load coordinates from a CSV file.
    
    :param csv_path: Path to the CSV file containing (x, y, z) coordinates
    :return: [node x 3] NumPy array of coordinates
    """
    # Load the CSV file, automatically recognizing the first row as the header
    df = pd.read_csv(csv_path)
    
    # Convert the DataFrame to a np array
    coordinates = df.to_numpy()
    
    return coordinates

def save_distance_matrix(matrix, output_path):
    """
    Save the distance matrix to a CSV file.
    
    :param matrix: [node x node] distance matrix
    :param output_path: Path to the output CSV file
    """
    np.savetxt(output_path, matrix, delimiter=',')
    print(f"Distance matrix saved to {output_path}")
    
csv_file = "derivatives/templates/atlas_2mm_2009c_coordinates.csv"
coords = load_coordinates(csv_file)

# Step 2: Compute the distance matrix
distance_matrix = compute_distance_matrix(coords)

# Step 3: Save the distance matrix to a CSV file
output_csv_file = "derivatives/templates/2mm_2009c_distance_matrix.csv"
save_distance_matrix(distance_matrix, output_csv_file)

# Print the result
print("Coordinates:")
print(coords)
print("\nDistance Matrix:")
print(distance_matrix)