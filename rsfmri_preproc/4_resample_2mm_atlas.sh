#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"

echo "###################################################################"
echo ".................Resampling epi with 2mm atlas..................."

#3 make epi into same size as 2mm atlas
function resample_epi { 
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 #anat="${input//\/func\//\/anat\/}"
 template="derivatives/templates/Schaefer2018_400Parcels_Tian_Subcortex_S4_2mm_2009c_NLinAsymm.nii.gz"
 output="${input%.nii.gz}_resampled.nii.gz" 
    
 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
		
  echo -e "Processing input: $input... \n"
  echo -e "With master: $template... \n"
		
  if [ -f "$output" ]; then
    echo "Output file $output already exists, skipping..."
  else
    3dresample -master "$template" -prefix "$output" -input "$input"
    echo "Resampled $input and saved as $output"
  fi
 else
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi
}

export -f resample_epi

find "$path_der" -type f -name 'sub-*_regressed_smoothed.nii.gz' > "$path_der/toresample_files.txt"

N=2
(
for ii in $(cat "$path_der/toresample_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   resample_epi "$ii" &
done
)

rm "$path_der/toresample_files.txt"