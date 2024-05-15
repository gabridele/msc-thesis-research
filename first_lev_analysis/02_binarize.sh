#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"

echo "###################################################################" 
echo ".....................Binarizing CSF image....................."

#2
function binarize_img { 
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 output="${input%probtissue.nii.gz}bin.nii.gz"
    
 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
		
  echo -e "Processing input: $input \n..."
		
  if [ -f "$output" ]; then
    echo "Output file $output already exists, skipping..."
  else
    fslmaths "$input" -thr 0.5 -bin "$output"
    echo "Binarized $input and saved as $output"
  fi
 else
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi

}

export -f binarize_img

find "$path_der" -type f -name '*CSF_probtissue.nii.gz' > "$path_der/input_files.txt"

N=50
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   binarize_img "$ii" & 
done
)

rm "$path_der/input_files.txt"