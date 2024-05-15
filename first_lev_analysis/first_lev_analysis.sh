#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"
numjobs=1


echo "###################################################################" 
echo ".....................Creating list of subjects....................."
#create list of subjects
if [ ! -f "subject_id_with_exclusions.txt" ]; then
    find . -maxdepth 1 -type d -name 'sub-*' | sed 's/.*\///' | sort > "subject_id_with_exclusions.txt"
fi

#0 make timings

echo "###################################################################" 
echo ".....................Making timings....................."

for subj in `cat "subject_id_with_exclusions.txt"`; do
	derivatives_dir="derivatives/$subj/func"
	cd "$subj/func"

	echo -e "Processing subject: $subj...\n"

	cat ${subj}_task-scap_events.tsv | awk '{if ($3 == 1 || $3 == 4) {print $1, "6.5", 1}}' > "../../$derivatives_dir/${subj}_task-scap_low_WM_1500.txt" &
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 == 2 || $3 == 5) {print $1, "8.0", 1}}' > "../../$derivatives_dir/${subj}_task-scap_low_WM_3000.txt" &
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 == 3 || $3 == 6) {print $1, "9.5", 1}}' > "../../$derivatives_dir/${subj}_task-scap_low_WM_4500.txt" &
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 == 7 || $3 == 10) {print $1, "6.5", 1}}' > "../../$derivatives_dir/${subj}_task-scap_high_WM_1500.txt" &
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 == 8 || $3 == 11) {print $1, "8.0", 1}}' > "../../$derivatives_dir/${subj}_task-scap_high_WM_3000.txt" &
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 == 9 || $3 == 12) {print $1, "9.5", 1}}' > "../../$derivatives_dir/${subj}_task-scap_high_WM_4500.txt" &

	# Convert to AFNI format
	echo "Converting to AFNI format..."
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_low_WM_1500.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_low_WM_1500.1D" &
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_low_WM_3000.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_low_WM_3000.1D" &
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_low_WM_4500.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_low_WM_4500.1D"	&
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_high_WM_1500.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_high_WM_1500.1D" &
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_high_WM_3000.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_high_WM_3000.1D" &
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_high_WM_4500.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_high_WM_4500.1D" &

	cd ../..
done

#0.1
echo "###################################################################" 
echo ".....................Processing motion regressors....................."

function process_regr {
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 input=$(basename "$input")
 output="${input%.tsv}_processed.tsv"

 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
  cd derivatives/$sub_id/func/
  mkdir temp_files
  pwd
  cp "$input" temp_files/
  cd temp_files
  combined_file="combined_columns.tsv"

  # Loop through the specified columns
  for index in {19..24}; do
   echo "Processing column $index of $sub_id"
   
   # Extract the current column to a temporary file
   cut -f "$index" "$input" > "temp_column_${index}.tsv"
   tail -n +2 "temp_column_${index}.tsv" > "tailed_temp_column_${index}.tsv"
   pwd
   # Compute squared numbers using 1deval
   1deval -expr 'a*a' -a "temp_column_${index}.tsv" > "squared_column_${index}.tsv"
   echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_2"}')\n$(cat "squared_column_${index}.tsv")" > "squared_column_${index}.tsv"

   # Calculate derivatives using 1d_tool.py
   1d_tool.py -infile "tailed_temp_column_${index}.tsv" -derivative -write "derivative_column_${index}.tsv"
   echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_der"}')\n$(cat "derivative_column_${index}.tsv")" > "derivative_column_${index}.tsv"

   # Compute squared derivatives using 1deval
   1deval -expr 'a*a' -a "derivative_column_${index}.tsv" > "squared_derivative_column_${index}.tsv"
   echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_der2"}')\n$(cat "squared_derivative_column_${index}.tsv")" > "squared_derivative_column_${index}.tsv"

   # Pasting all $index columns together
   paste "temp_column_${index}.tsv" "squared_column_${index}.tsv" "derivative_column_${index}.tsv" "squared_derivative_column_${index}.tsv" >> "temp_combined_columns_${index}.tsv"

  done
 
  # Pasting all combined column files together in single file -> final file of motion regressors
  paste temp_combined_columns_{19..24}.tsv > "$combined_file"
  mv "$combined_file" "../$output"
  cd ..
  rm -r temp_files
  cd ../../..
 else
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi
}

export -f process_regr

find "$path_der" -type f -name '*_task-scap_bold_confounds.tsv' > "$path_der/confounds_files.txt"
cat "$path_der/confounds_files.txt" | parallel -j "$numjobs" process_regr {}
rm "$path_der/confounds_files.txt"


#1
echo "###################################################################" 
echo ".....................Smoothing EPI....................."

function smooth {
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 mask="${input%_preproc.nii.gz}_brainmask.nii.gz" 
 output="${input%_preproc.nii.gz}_preproc_smoothed.nii.gz"

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

find "$path_der" -type f -name '*task-scap_bold_space-MNI152NLin2009cAsym_preproc.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" smooth {} "$mask"
rm "$path_der/input_files.txt"

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
cat "$path_der/input_files.txt" | parallel -j "$numjobs" binarize_img {}
rm "$path_der/input_files.txt"

#---------------------
echo "###################################################################"
echo ".................Resampling EPI with T1w brain mask..................."

#3 make epi into same size as t1 brain mask
function resample_epi { 
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 anat="${input//\/func\//\/anat\/}"
 mask="${anat%_task-scap*}_T1w_space-MNI152NLin2009cAsym_brainmask.nii.gz"
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
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi
}

export -f resample_epi
find "$path_der" -type f -name '*_task-scap_bold_space-MNI152NLin2009cAsym_preproc_smoothed.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" resample_epi {} "$mask"
rm "$path_der/input_files.txt"

echo "###################################################################" 
echo ".................Resampling mask of task with T1w brain mask..................."

# 3.1 resample mask of scap task
function resample_scap_mask { 
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 anat="${input//\/func\//\/anat\/}"
 mask="${anat%_task-scap*}_T1w_space-MNI152NLin2009cAsym_brainmask.nii.gz"
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
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi

}

export -f resample_scap_mask
find "$path_der" -type f -name '*_task-scap_bold_space-MNI152NLin2009cAsym_brainmask.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" resample_scap_mask {} "$mask"
rm "$path_der/input_files.txt"

echo "###################################################################" 
echo ".................Computing mean ts for CSF..................."

#4
function mean_ts {
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1) 
 anat="${input//\/func\//\/anat\/}"
 mask="${anat%_task-scap*}_T1w_space-MNI152NLin2009cAsym_class-CSF_bin.nii.gz"
 output="${input%_bold*}_meants_CSF.tsv" 
	
 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then

  echo -e "Processing input: $input \n..."
  echo -e "With mask: $mask... \n"
		
  if [ -f "$output" ]; then
    echo "Output file $output already exists, skipping..."
  else
    fslmeants -i "$input" -o "$output" -m "$mask"
    echo -e "csf\n$(cat "$output")" > "$output"
    #add "csf" header, cause it skips first row assuming it's header
  fi
 else
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi

}

export -f mean_ts
find "$path_der" -type f -name '*_preproc_smoothed_resampled.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" mean_ts {} "$mask"
rm "$path_der/input_files.txt"

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
  echo $regressor_tsv
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
cat "$path_der/input_files.txt" | parallel -j "$numjobs" deconvolve {} "$mask" "$events_low15" "$events_low30" "$events_low45" "$events_high15" "$events_high30" "$events_high45" "$regressor_wm" "$regressor_tsv" "$regressorCSF_tsv"
rm "$path_der/input_files.txt"

echo "###################################################################" 
echo ".................Performing fitting..................."

function fitting {
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 matrix="${input%_bold*}.xmat.1D"
 mask="${input%_preproc_*}_brainmask_resampled.nii.gz"
 fit_output="${input%_bold*}_fit.nii.gz"
 res_output="${input%_bold*}_REML_whitened_residuals.nii.gz"

 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then

  echo -e "Processing input: $input \n..."
  echo -e "With mask: $mask... \n"
  if [ -f "$output" ]; then
    echo "Output file $output already exists, skipping..."
  else
    3dREMLfit \
    -input "$input" \
    -matrix "$matrix" \
    -mask "$mask" \
    -Rbuck "$fit_output" \
    -fout \
    -tout \
    -Rwherr "$res_output" \
    -verb
  fi
 else
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi

}

export -f fitting
find "$path_der" -type f -name '*_preproc_smoothed_resampled.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" fitting {} "$mask" "$matrix"
rm "$path_der/input_files.txt"