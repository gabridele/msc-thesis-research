#!/bin/bash

base_dir="derivatives/preproc_dl"

# Loop through each subject directory
for subject_dir in "$base_dir"/sub-*/scap.feat/stats; do
    # Extract the subject ID
    subject_id=$(basename $(dirname $(dirname "$subject_dir")))

    # Path to the specific zstat29.nii.gz file
    zstat_file="$subject_dir/zstat27.nii.gz"

    # Check if the file exists
    if [ -f "$zstat_file" ]; then
        # Construct the new filename by adding the subject ID at the beginning
        new_filename="${subject_dir}/${subject_id}_zstat27.nii.gz"
        
        # Rename the file
        mv "$zstat_file" "$new_filename"
        
        # Output the new filename
        echo "Renamed $zstat_file to $new_filename"
    fi
done