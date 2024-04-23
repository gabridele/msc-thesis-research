#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"
#path_output="spreading_dynamics_clinical/derivatives/"
numjobs=1


echo "###################################################################" 
echo ".....................Creating list of subjects....................."
#create list of subjects
if [ ! -f "subjList.txt" ]; then
    find . -maxdepth 1 -type d -name 'sub-*' | sed 's/.*\///' | sort > "subjList.txt"
fi

echo "###################################################################" 
echo ".....................Making timings....................."

#0 make timings
for subj in `cat "subjList.txt"`; do
	derivatives_dir="derivatives/$subj/func"
	cd "$subj/func"
	echo "Processing subject: $subj"
	
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 >= 1 && $3 <= 6) {print $1}}' > "../../$derivatives_dir/${subj}_task-scap_low_WM.txt"
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 >= 7 && $3 <= 12) {print $1}}' > "../../$derivatives_dir/${subj}_task-scap_high_WM.txt"

	# Convert to AFNI format
	echo "Converting to AFNI format..."
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_low_WM.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_low_WM.txt"
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_high_WM.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_high_WM.txt"

	cd ../..
done

echo "###################################################################" 
echo ".....................Smoothing EPI....................."

#1
function smooth { 
    input="$1"
    mask="${input%_preproc.nii.gz}_brainmask.nii.gz" 
    output="${input%_preproc.nii.gz}_preproc_smoothed.nii.gz"
    
    if [ -f "$output" ]; then
        echo "Output file $output already exists, skipping..."
    else
        3dBlurInMask -input "$input" -mask "$mask" -FWHM 4 -prefix "$output"
        echo "Smoothed $input and saved as $output"
    fi
}

export -f smooth

find "$path_der" -type f -name '*task-scap_bold_space-MNI152*_preproc.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" smooth {} "$mask"
rm "$path_der/input_files.txt"

echo "###################################################################" 
echo ".....................Binarizing CSF image....................."

#2
function binarize_img { 
    input="$1"
    output="${input%probtissue.nii.gz}bin.nii.gz"
    
    if [ -f "$output" ]; then
        echo "Output file $output already exists, skipping..."
    else
        fslmaths "$input" -thr 0.5 -bin "$output"
        echo "Binarized $input and saved as $output"
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
    anat="${input//\/func\//\/anat\/}"
    mask="${anat%_task-scap*}_T1w_space-MNI*_brainmask.nii.gz"
    output="${input%.nii.gz}_resampled.nii.gz" 
    
    if [ -f "$output" ]; then
        echo "Output file $output already exists, skipping..."
    else
        3dresample -master "$mask" -prefix "$output" -input "$input"
        echo "Resampled $input and saved as $output"
    fi
}

export -f resample_epi
find "$path_der" -type f -name '*_task-scap_bold_space-MNI152*_preproc_smoothed.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" resample_epi {} "$mask"
rm "$path_der/input_files.txt"

echo "###################################################################" 
echo ".................Resampling mask of task with T1w brain mask..................."

# 3.1 resample mask of scap task
function resample_scap_mask { 
    input="$1"
    anat="${input//\/func\//\/anat\/}"
    mask="${anat%_task-scap*}_T1w_space-MNI*_brainmask.nii.gz"
    output="${input%.nii.gz}_resampled.nii.gz" 
    
    if [ -f "$output" ]; then
        echo "Output file $output already exists, skipping..."
    else
        3dresample -master "$mask" -prefix "$output" -input "$input"
        echo "Resampled $input and saved as $output"
    fi
}

export -f resample_scap_mask
find "$path_der" -type f -name '*_task-scap_bold_space-MNI*_brainmask.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" resample_scap_mask {} "$mask"
rm "$path_der/input_files.txt"

echo "###################################################################" 
echo ".................Computing mean ts for CSF..................."
function mean_ts {
    input="$1"
    anat="${input//\/func\//\/anat\/}"
    mask="${anat%_task-scap*}_T1w_space-MNI152NLin2009cAsym_class-CSF_probtissue_bin_resampled.nii.gz"
    output="${input%_bold_space*}_mean_timeseriesCSF.tsv"
    temp_output="$output.temp"

    # Add "csf" as the first line in a temporary file
    echo "csf" > "$temp_output"

    echo "Processing input: $input with mask: $mask"

    # Use fslmeants to process the input and append the output to the temporary file
    fslmeants -i "$input" -o -m "$mask" >> "$temp_output"

    # Rename the temporary file to the final output file
    mv "$temp_output" "$output"
}
#4
function mean_ts {  #make sure its MNI!!!!!!
	input="$1" 
	anat="${input//\/func\//\/anat\/}"
	mask="${anat%_task-scap*}_T1w_space-MNI*_class-CSF_bin.nii.gz"
	output="${input%_bold_space*}_meants_CSF.tsv" 
	
	echo "Processing input: $input with mask: $mask"
	
	fslmeants -i "$input" -o "$output" -m "$mask"
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
	mask="${input%_preproc_*}_brainmask_resampled.nii.gz"
	events_low="${input%_bold_space-MNI*}_low_WM.txt"
	events_high="${input%_bold_space-MNI*}_high_WM.txt"
	regressor_tsv="${input%_space*}_confounds.tsv"
	regressorCSF_tsv="${input%_bold_space*}_meants_CSF.tsv"
	output_xmat="${input%_bold_space-MNI*Asym_preproc_smoothed_resampled.nii.gz}.xmat.1D"
	output_jpg="${input%_bold_space-MNI*Asym_preproc_smoothed_resampled.nii.gz}.jpg"
	
	3dDeconvolve \
	-force_TR 2 \
	-mask "$mask" \ #mask di quel task
	-input "$input" \ #bold smoothed resampled
	-polort 'A' \
	-num_stimts 10 \
	-stim_times 1 "$events_low" 'GAM' -stim_label 1 low_WM \
	-stim_times 2 "$events_high" 'GAM' -stim_label 2 high_WM \
  	-stim_file 3 "$regressor_tsv"'[62]' -stim_base 3 -stim_label 3 TransX \
  	-stim_file 4 "$regressor_tsv"'[66]' -stim_base 4 -stim_label 4 TransY \
  	-stim_file 5 "$regressor_tsv"'[70]' -stim_base 5 -stim_label 5 TransZ \
  	-stim_file 6 "$regressor_tsv"'[74]' -stim_base 6 -stim_label 6 RotX \
  	-stim_file 7 "$regressor_tsv"'[78]' -stim_base 7 -stim_label 7 RotY \
  	-stim_file 8 "$regressor_tsv"'[82]' -stim_base 8 -stim_label 8 Rotz \
  	-stim_file 9 "$regressorCSF_tsv"'[0]' -stim_base 9 -stim_label 9 csf \
  	-stim_file 10 "$regressor_tsv"'[4]' -stim_base 10 -stim_label 10 wm \
	-fout \
	-tout \
  	-x1D "$output_xmat".xmat.1D \
  	-xjpeg "$output_jpg".jpg \
	#-x1D_stop \ docs say its useful only for testing
  	-jobs 1 \
  	-virtvec
}

export -f deconvolve
find "$path_der" -type f -name '*_task-scap_bold_space-MNI*_preproc_smoothed_resampled.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" deconvolve {} "$mask" "$events_low" "$events_high" "$regressor_tsv" "$regressorCSF_tsv"
rm "$path_der/input_files.txt"


#--------
#find "$path_raw" -type f -name '*circle*' > "$path_raw/input_rm.txt"
#cat "$path_raw/input_rm.txt" | parallel -j "$numjobs" rm {}
#------
# optional removing files
#find "$path_der" -type f -name '*+orig.BRIK' > "$path_der/input_files.txt"
#cat "$path_der/input_files.txt" | parallel -j "$numjobs" rm {}
#----
#--------