#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
# script to smooth data with 4mm option
path_der="derivatives/"

#1
echo "###################################################################" 
echo ".....................Smoothing EPI....................."

function smooth {
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 mask="${input%_regressed*}_task-rest_bold_space-MNI152NLin2009cAsym_brainmask.nii.gz" 
 output="${input%_regressed*}_regressed_smoothed.nii.gz"

 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
        
  echo -e "\n Processing input: $input ..."
  echo -e "\n With mask: $mask..."

  if [ -f "$output" ]; then
    echo -e "\n Output file $output already exists, skipping..."
  else
    3dBlurInMask -input "$input" -mask "$mask" -FWHM 4 -prefix "$output"
    echo -e "\n Smoothed $input and saved as $output"
  fi
 else
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi
}

export -f smooth

find "$path_der" -type f -name '*regressed_bandpass.nii.gz' > "$path_der/input_files.txt"

N=2
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   smooth "$ii" "$mask" & 
done
)
rm "$path_der/input_files.txt"