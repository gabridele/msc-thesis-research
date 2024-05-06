#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"
numjobs=2


#echo "###################################################################" 
#echo ".....................Creating list of subjects....................."
#create list of subjects
#if [ ! -f "subject_id_with_exclusions.txt" ]; then
#    find . -maxdepth 1 -type d -name 'sub-*' | sed 's/.*\///' | sort > "subject_id_with_exclusions.txt"
#fi

#echo "###################################################################" 
#echo ".....................Making timings....................."

#0 make timings

function timings {
 for subj in `cat "subject_id_with_exclusions.txt"`; do
  derivatives_dir="derivatives/$subj/func"
  cd "$subj/func"

  echo -e "Processing subject: $subj...\n"

  cat ${subj}_task-scap_events.tsv | awk '{if ($3 = 1 && $3 = 4) {print $1, 6.5, 1}}' > "../../$derivatives_dir/${subj}_task-scap_low_WM_1500.txt"
  cat ${subj}_task-scap_events.tsv | awk '{if ($3 = 2 && $3 = 5) {print $1, 8.0, 1}}' > "../../$derivatives_dir/${subj}_task-scap_low_WM_3000.txt"
  cat ${subj}_task-scap_events.tsv | awk '{if ($3 = 3 && $3 = 6) {print $1, 9.5, 1}}' > "../../$derivatives_dir/${subj}_task-scap_low_WM_4500.txt"	
  cat ${subj}_task-scap_events.tsv | awk '{if ($3 = 7 && $3 = 10) {print $1, 6.5, 1}}' > "../../$derivatives_dir/${subj}_task-scap_high_WM_1500.txt"
  cat ${subj}_task-scap_events.tsv | awk '{if ($3 = 8 && $3 = 11) {print $1, 8.0, 1}}' > "../../$derivatives_dir/${subj}_task-scap_high_WM_3000.txt"
  cat ${subj}_task-scap_events.tsv | awk '{if ($3 = 9 && $3 = 12) {print $1, 9.5, 1}}' > "../../$derivatives_dir/${subj}_task-scap_high_WM_4500.txt"

  # Convert to AFNI format
  echo "Converting to AFNI format..."
  timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_low_WM_1500.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_low_WM_1500.1D"
  timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_low_WM_3000.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_low_WM_3000.1D"
  timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_low_WM_4500.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_low_WM_4500.1D"	
  timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_high_WM_1500.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_high_WM_1500.1D"
  timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_high_WM_3000.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_high_WM_3000.1D"
  timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_high_WM_4500.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_high_WM_4500.1D"

  cd ../..
 done
}

export -f timings

parallel -j "$numjobs" timings {}

echo "###################################################################" 
echo ".....................Smoothing EPI....................."

#1
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
 regressor_tsv="${input%_space*}_confounds.tsv"
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
    -num_stimts 14 \
    -stim_times 1 "$events_low15" 'BLOCK(6.5,1)' -stim_label 1 low_WM_1500 \
    -stim_times 2 "$events_low30" 'BLOCK(8,1)' -stim_label 2 low_WM_3000 \
    -stim_times 3 "$events_low45" 'BLOCK(9.5,1)' -stim_label 3 low_WM_4500 \
    -stim_times 4 "$events_high15" 'BLOCK(6.5,1)' -stim_label 4 high_WM_1500 \
    -stim_times 5 "$events_high30" 'BLOCK(8,1)' -stim_label 5 high_WM_3000 \
    -stim_times 6 "$events_high45" 'BLOCK(9.5,1)' -stim_label 6 high_WM_4500 \
    -stim_file 7 "$regressor_tsv"'[18]' -stim_base 7 -stim_label 7 TransX \
    -stim_file 8 "$regressor_tsv"'[19]' -stim_base 8 -stim_label 8 TransY \
    -stim_file 9 "$regressor_tsv"'[20]' -stim_base 9 -stim_label 9 TransZ \
    -stim_file 10 "$regressor_tsv"'[21]' -stim_base 10 -stim_label 10 RotX \
    -stim_file 11 "$regressor_tsv"'[22]' -stim_base 11 -stim_label 11 RotY \
    -stim_file 12 "$regressor_tsv"'[23]' -stim_base 12 -stim_label 12 Rotz \
    -stim_file 13 "$regressorCSF_tsv"'[0]' -stim_base 13 -stim_label 13 csf \
    -stim_file 14 "$regressor_tsv"'[0]' -stim_base 14 -stim_label 14 wm \
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
cat "$path_der/input_files.txt" | parallel -j "$numjobs" deconvolve {} "$mask" "$events_low" "$events_high" "$regressor_tsv" "$regressorCSF_tsv"
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


#--------
#find "$path_der" -type f -name '*WM*' > "./input_rm.txt"
#cat "./input_rm.txt" | parallel -j 2 rm {}
#------
# optional removing files
#find "$path_der" -type f -name '*+orig.BRIK' > "$path_der/input_files.txt"
#cat "$path_der/input_files.txt" | parallel -j "$numjobs" rm {}
#----
#--------