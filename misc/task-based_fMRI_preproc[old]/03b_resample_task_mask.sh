#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"


echo "###################################################################" 
echo ".................Resampling mask of task with T1w brain mask..................."

# 3.1 resample mask of scap task
function resample_task_mask { 
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 anat="${input//\/func\//\/anat\/}"
 mask="${anat%_task-rest*}_T1w_space-MNI152NLin2009cAsym_brainmask.nii.gz"
 output="${input%.nii.gz}_resampled.nii.gz"

 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
		
  echo -e "Processing input: $input \n..."
  echo -e "With mask: $mask... \n"
		
  if [ -f "$output" ]; then
    echo "Output file $output already exists, skipping..."
  else
    3dresample -master "$mask" -prefix "$output" -input "$input"
    echo "Resampled $input and saved as $output"
  fi
 else
  echo -e "\nSubject $sub_id is excluded. Skipping..."
 fi

}

export -f resample_task_mask

find "$path_der" -type f -name '*_task-rest_bold_space-MNI*_brainmask.nii.gz' > "$path_der/input_files.txt"

N=2
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   resample_task_mask "$ii" "$mask" & 
done
)

rm "$path_der/input_files.txt"