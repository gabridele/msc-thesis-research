#!/bin/bash

# Directory containing the files
base_dir="to_correl"

# Output file for the correlation results
output_file="correlation_results.txt"

# Function to extract subject ID from filename
extract_subject_id() {
    local file="$1"
    # Use regex to extract the subject ID
    basename "$file" | grep -oP 'sub-\d+' | sed 's/sub-//'
}

# Function to perform correlation for a single pair
perform_correlation() {
    local dec_file="$1"
    local non_dec_file="$2"
    local subject_id="$3"
    local mask_file="derivatives/sub-${subject_id}/func/sub-${subject_id}_task-scap_bold_space-MNI152NLin2009cAsym_brainmask_resampled.nii.gz"

    echo "Processing dec file: $dec_file"
    echo "Using mask file: $mask_file"

    # Run 3ddot command to calculate correlation with mask file
    echo "for sub-$subject_id $dec_file and mask file $mask_file:" >> "$output_file"
    echo "" >> "$output_file"
    3ddot -doeta2 -mask "$mask_file" "$dec_file" "$non_dec_file" >> "$output_file" 2>&1
    echo "" >> "$output_file"  # Add a newline after each correlation result
}

# Ensure the output file is empty or created
> "$output_file"

# Find all dec files and process them in parallel
find "$base_dir" -type f -name "dec_*.nii.gz" | sort | while read -r dec_file; do
    # Determine non_dec_file by removing "dec_" prefix
    non_dec_file="${dec_file/dec_/}"

    # Extract subject ID
    subject_id=$(extract_subject_id "$dec_file")

    # Perform correlation for each pair
    perform_correlation "$dec_file" "$non_dec_file" "$subject_id" &
done

# Wait for all background processes to finish
wait

echo "Correlation calculation complete. Results saved to $output_file"