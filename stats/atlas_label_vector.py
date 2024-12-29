import numpy as np

def create_label_vector(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    label_vector = []
    for i in range(0, len(lines), 2):
        label = lines[i].strip()
        if 'rh' or 'RH' in label:
            label_vector.append(True)
        elif 'lh' or 'LH' in label:
            label_vector.append(False)

    return label_vector

# Example usage
file_path = '/Users/gabrieledele/Downloads/sSchaefer2018_400Parcels_7Networks_order_Tian_Subcortex_S4_label.txt'
label_vector = create_label_vector(file_path)
print(label_vector)

# Save the label vector to a .npy file
output_file_path = '/Users/gabrieledele/Downloads/label_vector.npy'
np.save(output_file_path, label_vector)