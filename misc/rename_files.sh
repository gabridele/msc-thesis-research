#!/bin/bash

base_dir="ddl"

# Loop through each subject directory
find "$base_dir" -type d -path "*/sub-*/scap.feat/stats" | while read -r subject_dir; do
    # Extract the subject ID
    subject_id=$(basename "$(dirname "$(dirname "$subject_dir")")")
   
    # Path to the specific cope27.nii.gz file
    cope_file="$subject_dir/cope31.nii.gz"

    echo "$cope_file"
    # Check if the file exists
    if [ -f "$cope_file" ]; then
        # Construct the new filename by adding the subject ID at the beginning
        new_filename="${subject_dir}/${subject_id}_cope31.nii.gz"
        
        # Rename the file
        mv "$cope_file" "$new_filename"
        
        # Output the new filename
        echo "Renamed $cope_file to $new_filename"
    
    fi
done