#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"
numjobs=1


echo "###################################################################" 
#echo ".....................Creating list of subjects....................."
#create list of subjects
if [ ! -f "subject_id_with_exclusions.txt" ]; then
    find . -maxdepth 1 -type d -name 'sub-*' | sed 's/.*\///' | sort > "subject_id_with_exclusions.txt"
fi

#echo "###################################################################" 
#echo ".....................Making timings....................."

#0 make timings
for subj in `cat "subject_id_with_exclusions.txt"`; do
	derivatives_dir="derivatives/$subj/func"
	cd "$subj/func"

	echo -e "Processing subject: $subj...\n"
	
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 >= 1 && $3 <= 6) {print $1, $2, 1}}' > "../../$derivatives_dir/${subj}_task-scap_low_WM.txt"
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 >= 7 && $3 <= 12) {print $1, $2, 1}}' > "../../$derivatives_dir/${subj}_task-scap_high_WM.txt"

	# Convert to AFNI format
	echo "Converting to AFNI format..."
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_low_WM.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_low_WM.1D"
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_task-scap_high_WM.txt" -write_timing "../../$derivatives_dir/${subj}_task-scap_high_WM.1D"

	cd ../..
done

echo "###################################################################" 
echo ".....................Smoothing EPI....................."

#1
function smooth { 
    input="$1"
    mask="${input%_preproc.nii.gz}_brainmask.nii.gz" 
    output="${input%_preproc.nii.gz}_preproc_smoothed.nii.gz"
    
	echo -e "Processing input: $input \n..."
	echo -e "With mask: $mask... \n"

    if [ -f "$output" ]; then
        echo "Output file $output already exists, skipping..."
    else
        3dBlurInMask -input "$input" -mask "$mask" -FWHM 4 -prefix "$output"
        echo "Smoothed $input and saved as $output"
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
    output="${input%probtissue.nii.gz}bin.nii.gz"
    
	echo -e "Processing input: $input \n..."

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
    mask="${anat%_task-scap*}_T1w_space-MNI152NLin2009cAsym_brainmask.nii.gz"
    output="${input%.nii.gz}_resampled.nii.gz" 
    
	echo -e "Processing input: $input \n..."
	echo -e "With mask: $mask... \n"

    if [ -f "$output" ]; then
        echo "Output file $output already exists, skipping..."
    else
        3dresample -master "$mask" -prefix "$output" -input "$input"
        echo "Resampled $input and saved as $output"
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
    anat="${input//\/func\//\/anat\/}"
    mask="${anat%_task-scap*}_T1w_space-MNI152NLin2009cAsym_brainmask.nii.gz"
    output="${input%.nii.gz}_resampled.nii.gz" 
    
	echo -e "Processing input: $input \n..."
	echo -e "With mask: $mask... \n"
    
	if [ -f "$output" ]; then
        echo "Output file $output already exists, skipping..."
    else
        3dresample -master "$mask" -prefix "$output" -input "$input"
        echo "Resampled $input and saved as $output"
    fi
}

export -f resample_scap_mask
find "$path_der" -type f -name '*_task-scap_bold_space-MNI152NLin2009cAsym_brainmask.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" resample_scap_mask {} "$mask"
rm "$path_der/input_files.txt"

echo "###################################################################" 
echo ".................Computing mean ts for CSF..................."

#4
function mean_ts {  #make sure its MNI!!!!!!
	input="$1" 
	anat="${input//\/func\//\/anat\/}"
	mask="${anat%_task-scap*}_T1w_space-MNI152NLin2009cAsym_class-CSF_bin.nii.gz"
	output="${input%_bold*}_meants_CSF.tsv" 
	
	echo -e "Processing input: $input \n..."
	echo -e "With mask: $mask... \n"
	
	if [ -f "$output" ]; then
        echo "Output file $output already exists, skipping..."
    else
		fslmeants -i "$input" -o "$output" -m "$mask"
		echo -e "csf\n$(cat "$output")" > "$output"
		# add "csf" header, cause it skips first row assuming it's header
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
	mask="${input%_preproc_*}_brainmask_resampled.nii.gz"
	events_low="${input%_bold*}_low_WM.txt"
	events_high="${input%_bold*}_high_WM.txt"
	regressor_tsv="${input%_space*}_confounds.tsv"
	regressorCSF_tsv="${input%_bold*}_meants_CSF.tsv"
	output_xmat="${input%_bold*}.xmat.1D"
	output_jpg="${input%_bold*}.jpg"
	
	echo -e "Processing input: $input \n..."
	echo -e "With mask: $mask... \n"
	
	3dDeconvolve \
	-force_TR 2 \
	-mask "$mask" \
	-input "$input" \
	-polort 'A' \
	-num_stimts 10 \
	-stim_times 1 "$events_low" 'BLOCK(5,1)' -stim_label 1 low_WM \
	-stim_times 2 "$events_high" 'BLOCK(5,1)' -stim_label 2 high_WM \
  	-stim_file 3 "$regressor_tsv"'[18]' -stim_base 3 -stim_label 3 TransX \
  	-stim_file 4 "$regressor_tsv"'[19]' -stim_base 4 -stim_label 4 TransY \
  	-stim_file 5 "$regressor_tsv"'[20]' -stim_base 5 -stim_label 5 TransZ \
  	-stim_file 6 "$regressor_tsv"'[21]' -stim_base 6 -stim_label 6 RotX \
  	-stim_file 7 "$regressor_tsv"'[22]' -stim_base 7 -stim_label 7 RotY \
  	-stim_file 8 "$regressor_tsv"'[23]' -stim_base 8 -stim_label 8 Rotz \
  	-stim_file 9 "$regressorCSF_tsv"'[0]' -stim_base 9 -stim_label 9 csf \
  	-stim_file 10 "$regressor_tsv"'[0]' -stim_base 10 -stim_label 10 wm \
	-fout \
	-tout \
  	-x1D "$output_xmat" \
  	-xjpeg "$output_jpg" \
  	-jobs 1 \
  	-virtvec
}
#mask di quel task
#bold smoothed resampled
#-x1D_stop \ docs say its useful only for testing

export -f deconvolve
find "$path_der" -type f -name '*_preproc_smoothed_resampled.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" deconvolve {} "$mask" "$events_low" "$events_high" "$regressor_tsv" "$regressorCSF_tsv"
rm "$path_der/input_files.txt"

echo "###################################################################" 
echo ".................Performing fitting..................."

function fitting {
	input="$1"
	matrix="${input%_bold*}.xmat.1D"
	mask="${input%_preproc_*}_brainmask_resampled.nii.gz"
	fit_output="${input%_bold*}_fit.nii.gz"
	res_output="${input%_bold*}_REML_whitened_residuals.nii.gz"

	echo -e "Processing input: $input \n..."
	echo -e "With mask: $mask... \n"

	3dREMLfit \
	-input "$input" \
	-matrix "$matrix" \
	-mask "$mask" \
	-Rbuck "$fit_output" \
	-fout \
	-tout \
	-Rwherr "$res_output" \
	-verb 
	#-Rerrts sub-376_ses-postop_task-es_run-03_REML_residuals.nii.gz \
	#-Rwherr sub-376_ses-postop_task-es_run-03_REML_whitened_residuals.nii.gz \
	#-Oerrts sub-376_ses-postop_task-es_run-03_OLSQ_residuals.nii.gz \
	#-verb

}

export -f fitting
find "$path_der" -type f -name '*_preproc_smoothed_resampled.nii.gz' > "$path_der/input_files.txt"
cat "$path_der/input_files.txt" | parallel -j "$numjobs" fitting {} "$mask" "$matrix"
rm "$path_der/input_files.txt"


#--------
#find "$path_der" -type f -name '*WM*' > "$./input_rm.txt"
#cat "./input_rm.txt" | parallel -j 2 rm {}
#------
# optional removing files
#find "$path_der" -type f -name '*+orig.BRIK' > "$path_der/input_files.txt"
#cat "$path_der/input_files.txt" | parallel -j "$numjobs" rm {}
#----
#--------