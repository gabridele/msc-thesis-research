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

# Example Usage
csv_file = "/Users/gabrieledele/Library/Containers/io.mountainduck/Data/Library/Application Support/Mountain Duck/Volumes.noindex/192.168.176.122 – SFTP.localized/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/templates/atlas_2mm_2009c_coordinates.csv"  # Replace with your CSV file path
coords = load_coordinates(csv_file)

# Step 2: Compute the distance matrix
distance_matrix = compute_distance_matrix(coords)

# Print the result
print("Coordinates:")
print(coords)
print("\nDistance Matrix:")
print(distance_matrix)