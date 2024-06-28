#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"


echo "###################################################################" 
echo ".................Computing mean ts for CSF..................."

#4
function mean_ts {
  input="$1"
  sub_id=$(basename "$input" | cut -d'_' -f1) 
  anat="${input//\/func\//\/anat\/}"
  mask="${anat%_task-rest*}_T1w_space-MNI152NLin2009cAsym_class-CSF_bin.nii.gz"
  output="${input%_bold*}_meants_CSF.tsv"
  
  total_subjects=$(grep -c "" "subject_id_with_exclusions.txt")
  
  if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
    echo -e "Processing input: $input \n..."
    echo -e "With mask: $mask... \n"
    
    if [ -f "$output" ]; then
      echo "Output file $output already exists, skipping..."
    else
      fslmeants -i "$input" -o "$output" -m "$mask"
      echo -e "csf\n$(cat "$output")" > "$output"
      # add "csf" header, assuming it skips first row assuming it's header
    fi
    
    ((subjects_processed++))
    
    echo "Processed $subjects_processed/$total_subjects subjects."
  else
    echo -e "\n Subject $sub_id is excluded. Skipping..."
  fi
}

export -f mean_ts

find "$path_der" -type f -name '*rest*MNI*_preproc_resampled.nii.gz' > "$path_der/input_files.txt"
subjects_processed=0
N=80
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   mean_ts "$ii" "$mask" & 
done
)
rm "$path_der/input_files.txt"