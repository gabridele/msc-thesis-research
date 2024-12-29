import subprocess
import numpy as np
import nibabel as nib
import csv

def extract_coordinates(atlas_path):
    # Get unique labels from the atlas
    atlas_img = nib.load(atlas_path)
    atlas_data = atlas_img.get_fdata()
    labels = np.unique(atlas_data)

    coordinates = {}
    for label in labels:
        if label == 0:
            continue  # Skip background

        # Create a temporary mask for the current label
        mask_path = f'/tmp/label_{int(label)}.nii.gz'
        nib.save(nib.Nifti1Image((atlas_data == label).astype(np.uint8), atlas_img.affine), mask_path)

        # Use fslstats to get the center of mass
        # -c to output coordinates in mm / -C for voxel coordinates
        result = subprocess.run(
            ['fslstats', mask_path, '-c'],
            stdout=subprocess.PIPE
        )
        com = result.stdout.decode('utf-8').strip().split()
        com = [float(coord) for coord in com]
        coordinates[label] = com

    return coordinates

def save_coordinates_to_csv(coordinates, csv_path):
    with open(csv_path, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['Label', 'X', 'Y', 'Z'])
        for label, com in coordinates.items():
            writer.writerow([int(label)] + com)

# cd to dataset path
# Path to the atlas
atlas_path = 'derivatives/templates/Schaefer2018_400Parcels_Tian_Subcortex_S4_2mm_2009c_NLinAsymm.nii.gz'
coordinates = extract_coordinates(atlas_path)

# Print the extracted coordinates
print("Region Coordinates:")
for label, com_world in coordinates.items():
    x, y, z = com_world
    print(f"Label {int(label)}: ({x}, {y}, {z})")
    
# Save the coordinates to a CSV file
csv_path = 'derivatives/templates/atlas_2mm_2009c_coordinates.csv'
save_coordinates_to_csv(coordinates, csv_path)

print(f"Coordinates saved to {csv_path}")