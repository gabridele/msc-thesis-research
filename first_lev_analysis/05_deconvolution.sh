#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"

echo "###################################################################" 
echo ".................Performing deconvolution..................."

#5
function deconvolve {
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 mask="${input%_preproc_*}_brainmask_resampled.nii.gz"
 events_low15="${input%_bold*}_low_WM_1500.1D"
 events_low30="${input%_bold*}_low_WM_3000.1D"
 events_low45="${input%_bold*}_low_WM_4500.1D"
 events_high15="${input%_bold*}_high_WM_1500.1D"
 events_high30="${input%_bold*}_high_WM_3000.1D"
 events_high45="${input%_bold*}_high_WM_4500.1D"
 regressor_wm="${input%_space*}_confounds.tsv"
 regressor_tsv="${input%_space*}_confounds_processed.tsv"
 regressorCSF_tsv="${input%_bold*}_meants_CSF.tsv"
 output_xmat="${input%_bold*}.xmat.1D"
 output_jpg="${input%_bold*}.jpg"


 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
  echo -e "Processing input: $input \n..."
  echo -e "With mask: $mask... \n"
  if [ -f "$output" ]; then
    echo "Output file $output already exists, skipping..."
  else
    3dDeconvolve \
    -force_TR 2 \
    -mask "$mask" \
    -input "$input" \
    -polort 'A' \
    -bucket "derivatives/$sub_id/func/"$sub_id"_scap_decon_outputs"/Decon \
    -num_stimts 32 \
    -stim_times 1 "$events_low15" 'BLOCK(6.5,1)' -stim_label 1 low_WM_1500 \
    -stim_times 2 "$events_low30" 'BLOCK(8,1)' -stim_label 2 low_WM_3000 \
    -stim_times 3 "$events_low45" 'BLOCK(9.5,1)' -stim_label 3 low_WM_4500 \
    -stim_times 4 "$events_high15" 'BLOCK(6.5,1)' -stim_label 4 high_WM_1500 \
    -stim_times 5 "$events_high30" 'BLOCK(8,1)' -stim_label 5 high_WM_3000 \
    -stim_times 6 "$events_high45" 'BLOCK(9.5,1)' -stim_label 6 high_WM_4500 \
    -stim_file 7 "$regressor_tsv"'[0]' -stim_base 7 -stim_label 7 TransX \
    -stim_file 8 "$regressor_tsv"'[4]' -stim_base 8 -stim_label 8 TransY \
    -stim_file 9 "$regressor_tsv"'[8]' -stim_base 9 -stim_label 9 TransZ \
    -stim_file 10 "$regressor_tsv"'[12]' -stim_base 10 -stim_label 10 RotX \
    -stim_file 11 "$regressor_tsv"'[16]' -stim_base 11 -stim_label 11 RotY \
    -stim_file 12 "$regressor_tsv"'[20]' -stim_base 12 -stim_label 12 RotZ \
    -stim_file 13 "$regressor_tsv"'[2]' -stim_base 13 -stim_label 13 TransXd \
    -stim_file 14 "$regressor_tsv"'[6]' -stim_base 14 -stim_label 14 TransYd \
    -stim_file 15 "$regressor_tsv"'[10]' -stim_base 15 -stim_label 15 TransZd \
    -stim_file 16 "$regressor_tsv"'[14]' -stim_base 16 -stim_label 16 RotXd \
    -stim_file 17 "$regressor_tsv"'[18]' -stim_base 17 -stim_label 17 RotYd \
    -stim_file 18 "$regressor_tsv"'[22]' -stim_base 18 -stim_label 18 RotZd \
    -stim_file 19 "$regressor_tsv"'[1]' -stim_base 19 -stim_label 19 TransX2 \
    -stim_file 20 "$regressor_tsv"'[5]' -stim_base 20 -stim_label 20 TransY2 \
    -stim_file 21 "$regressor_tsv"'[9]' -stim_base 21 -stim_label 21 TransZ2 \
    -stim_file 22 "$regressor_tsv"'[13]' -stim_base 22 -stim_label 22 RotX2 \
    -stim_file 23 "$regressor_tsv"'[17]' -stim_base 23 -stim_label 23 RotY2 \
    -stim_file 24 "$regressor_tsv"'[21]' -stim_base 24 -stim_label 24 RotZ2 \
    -stim_file 25 "$regressor_tsv"'[3]' -stim_base 25 -stim_label 25 TransXd2 \
    -stim_file 26 "$regressor_tsv"'[7]' -stim_base 26 -stim_label 26 TransYd2 \
    -stim_file 27 "$regressor_tsv"'[11]' -stim_base 27 -stim_label 27 TransZd2 \
    -stim_file 28 "$regressor_tsv"'[15]' -stim_base 28 -stim_label 28 RotXd2 \
    -stim_file 29 "$regressor_tsv"'[19]' -stim_base 29 -stim_label 29 RotYd2 \
    -stim_file 30 "$regressor_tsv"'[23]' -stim_base 30 -stim_label 30 RotZd2 \
    -stim_file 31 "$regressorCSF_tsv"'[0]' -stim_base 31 -stim_label 31 csf \
    -stim_file 32 "$regressor_wm"'[0]' -stim_base 32 -stim_label 32 wm \
    -fout \
    -tout \
    -x1D "$output_xmat" \
    -xjpeg "$output_jpg" \
    -jobs 2 \
    -virtvec
  fi
 else
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi

}
#mask di quel task
#bold smoothed resampled
#BLOCK perché la funzione è boxcar aka tutto zero tranne dove è un intervallo diverso da zero e costante
#-x1D_stop \ docs say its useful only for testing

export -f deconvolve

find "$path_der" -type f -name '*_preproc_smoothed_resampled.nii.gz' > "$path_der/input_files.txt"

N=1
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   smooth "$ii" "$mask" "$events_low15" "$events_low30" "$events_low45" "$events_high15" "$events_high30" "$events_high45" "$regressor_wm" "$regressor_tsv" "$regressorCSF_tsv" & 
done
)
rm "$path_der/input_files.txt"

