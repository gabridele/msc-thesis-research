#!/bin/bash

path_input="spreading_dynamics_clinical/derivatives/"
path_output="spreading_dynamics_clinical/derivatives/"
path_raw="spreading_dynamics_clinical"
numjobs=1

#--------
#find "$path_raw" -type f -name '*circle*' > "$path_raw/input_rm.txt"
#cat "$path_raw/input_rm.txt" | parallel -j "$numjobs" rm {}
#------

#create list of subjects
if [ ! -f subjList.txt ]; then
    find . -maxdepth 1 -type d -name 'sub-*' | sed 's/.*\///' | sort > subjList.txt
fi

#0 make timings
# Loop over all subjects and format timing files into FSL format
for subj in `cat subjList.txt`; do
	derivatives_dir="derivatives/$subj/func"
	cd "$subj/func"
	echo "Processing subject: $subj"
	
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 >= 1 && $3 <= 6) {print $1}}' > "../../$derivatives_dir/${subj}_low_WM.txt"
	cat ${subj}_task-scap_events.tsv | awk '{if ($3 >= 7 && $3 <= 12) {print $1}}' > "../../$derivatives_dir/${$subj}_high_WM.txt"

	# Now convert to AFNI format
	echo "Converting to AFNI format..."
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_low_WM.txt" -write_timing "../../$derivatives_dir/${subj}_low_WM.txt"
	timing_tool.py -fsl_timing_files "../../$derivatives_dir/${subj}_high_WM.txt" -write_timing "../../$derivatives_dir/${subj}_high_WM.txt"

	cd ../..
done

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

find "$path_input" -type f -name '*task-scap_bold_space-MNI152*_preproc.nii.gz' > "$path_input/input_files.txt"
cat "$path_input/input_files.txt" | parallel -j "$numjobs" smooth {} "$mask"
rm "$path_input/input_files.txt"

# optional removing files
#find "$path_input" -type f -name '*+orig.BRIK' > "$path_input/input_files.txt"
#cat "$path_input/input_files.txt" | parallel -j "$numjobs" rm {}
#----

#2
function binarize_img { 
    input="$1"
    output="${input%nii.gz}_bin.nii.gz"
    
    if [ -f "$output" ]; then
        echo "Output file $output already exists, skipping..."
    else
        fslmaths "$input" -thr 0.5 -bin "$output"
        echo "Binarized $input and saved as $output"
    fi
}

export -f binarize_img

find "$path_input" -type f -name '*CSF_probtissue.nii.gz' > "$path_input/input_files.txt"
cat "$path_input/input_files.txt" | parallel -j "$numjobs" binarize_img {}
rm "$path_input/input_files.txt"

#---------------------

#3 make epi into same size as t1 brain mask
function resample { 
    input="$1"
    anat="${input//\/func\//\/anat\/}"
    mask="${anat%_task-scap*}_T1w_space-MNI152NLin2009cAsym_class-CSF_resampled.nii.gz"
    output="${input%.nii.gz}_resampled.nii.gz" 
    
    if [ -f "$output" ]; then
        echo "Output file $output already exists, skipping..."
    else
        3dresample -master "$mask" -prefix "$output" -input "$input"
        echo "Resampled $input and saved as $output"
    fi
}

export -f resample
find "$path_input" -type f -name '*_task-scap_bold_space-MNI152*_preproc_smoothed.nii.gz' > "$path_input/input_files.txt"
cat "$path_input/input_files.txt" | parallel -j "$numjobs" resample {} "$mask"
rm "$path_input/input_files.txt"

#5
function mean_ts {  #make sure its MNI!!!!!!
	input="$1" 
	anat="${input//\/func\//\/anat\/}"
	mask="${anat%_task-scap*}_T1w_space-MNI152NLin2009cAsym_class-CSF_probtissue_bin_resampled.nii.gz"
	output="${input%_bold_space*}_mean_timeseriesCSF.tsv" 
	
	echo "Processing input: $input with mask: $mask"
	
	fslmeants -i "$input" -o "$output" -m "$mask"
}
export -f mean_ts
find "$path_raw" -type f -name '*_preproc_smoothed_resampled.nii.gz' > "$path_input/input_files.txt"
cat "$path_input/input_files.txt" | parallel -j "$numjobs" mean_ts {} "$mask"
rm "$path_input/input_files.txt"

#6
function deconvolve {
	input="$1"
	mask="${input%_preproc_smoothed_resampled.nii.gz}_brainmask.nii.gz"
	events_low="$/home/gabridele/Desktop/dataset/psych_dataset/sub-10159/func/low_circle.1D"
	events_high="$"
	regressor_tsv="$"
	regressorCSF_tsv="$"
	output_xmat="${input%_bold_space-MNI152NLin2009cAsym_preproc_smoothed_resampled.nii.gz}.xmat.1D"
	output_jpg="${input%_bold_space-MNI152NLin2009cAsym_preproc_smoothed_resampled.nii.gz}.jpg"
	
	3dDeconvolve \
	-force_TR 2 \
	-mask "$mask" \ #mask di quel task
	-input "$input" \ #bold smoothed resampled
	-polort 'A' \
	-num_stimts 10 \
	-stim_times 1 "$events_low" 'GAM' -stim_label 1 low_WM \ #sub-376_ses-postop_task-es_run-03_events_onset.txt
	-stim_times 2 "$events_high" 'GAM' -stim_label 2 high_WM \ #sub-376_ses-postop_task-es_run-03_events_onset.txt
  	-stim_file 3 "$regressor_tsv"'[62]' -stim_base 3 -stim_label 3 TransX \ #sub-376_ses-postop_task-es_run-03_desc-confounds_regressors.tsv
  	-stim_file 4 "$regressor_tsv"'[66]' -stim_base 4 -stim_label 4 TransY \
  	-stim_file 5 "$regressor_tsv"'[70]' -stim_base 5 -stim_label 5 TransZ \
  	-stim_file 6 "$regressor_tsv"'[74]' -stim_base 6 -stim_label 6 RotX \
  	-stim_file 7 "$regressor_tsv"'[78]' -stim_base 7 -stim_label 7 RotY \
  	-stim_file 8 "$regressor_tsv"'[82]' -stim_base 8 -stim_label 8 Rotz \
  	-stim_file 9 "$regressorCSF_tsv"'[0]' -stim_base 9 -stim_label 9 csf \
  	-stim_file 10 "$regressor_tsv"'[4]' -stim_base 10 -stim_label 10 wm \
  	-x1D "$output_xmat".xmat.1D \
  	-xjpeg "$output_jpg".jpg \
  	-x1D_stop \
  	-jobs 1 \
  	-virtvec
}

export -f deconvolve
find "$path_input" -type f -name '*_task-scap_bold_space-MNI152NLin2009cAsym_preproc_smoothed_resampled.nii.gz' > "$path_input/input_files.txt"


if [ ! -f subjList.txt ]; then
        ls -d sub-?? > subjList.txt
fi

#Loop over all subjects and format timing files into FSL format
for subj in `cat participants.tsv'[0]'` ; do
        cd $subj/func #Navigate to the subject's func directory, which contains the timing files
        
        #Extract the onset times for the incongruent and congruent trials for each run. NOTE: This script only extracts the trials in which the subject made a correct response. Accuracy is nearly 100% for all subjects, but as an exercise the student can modify this to extract the incorrect trials as well.
        cat ${subj}_task-flanker_run-1_events.tsv | awk '{if ($3=="incongruent_correct") {print $1, $2, "1"}}' > low_WM.txt
        cat ${subj}_task-flanker_run-1_events.tsv | awk '{if ($3=="congruent_correct") {print $1, $2, "1"}}' > high_WM.txt
     
        cd ../..
done


-miniconda
-fsl
-numpy
-scipy
-pandas
-afni
-ANTs
env neuroimg
-nibabel 
-nilearn
-mrtrix
-dipy

3dDeconvolve \
-force_TR 2 \
-mask '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap_bold_space-MNI152NLin2009cAsym_brainmask.nii.gz' \
-input '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap_bold_space-MNI152NLin2009cAsym_preproc_smoothed_resampled2.nii.gz' \
-polort 'A' \
-local_times \
-num_stimts 10 \
-stim_times 1 '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/low_WM.txt' 'GAM' -stim_label 1 low_WM \
-stim_times 2 '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/high_WM.txt' 'GAM' -stim_label 2 high_WM \
-stim_file 3 '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap_bold_confounds.tsv''[18]' -stim_base 3 -stim_label 3 TransX \
-stim_file 4 '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap_bold_confounds.tsv''[19]' -stim_base 4 -stim_label 4 TransY \
-stim_file 5 '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap_bold_confounds.tsv''[20]' -stim_base 5 -stim_label 5 TransZ \
-stim_file 6 '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap_bold_confounds.tsv''[21]' -stim_base 6 -stim_label 6 RotX \
-stim_file 7 '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap_bold_confounds.tsv''[22]' -stim_base 7 -stim_label 7 RotY \
-stim_file 8 '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap_bold_confounds.tsv''[23]' -stim_base 8 -stim_label 8 RotZ \
-stim_file 9 '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap_bold_meants_CSF.tsv''[0]' -stim_base 9 -stim_label 9 csf \
-stim_file 10 '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap_bold_confounds.tsv''[0]' -stim_base 10 -stim_label 10 wm \
-x1D '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap.xmat.1D' \
-xjpeg '/home/gabridele/Desktop/spreading_dynamics_clinical/derivatives/sub-10159/func/sub-10159_task-scap.jpg' \
-x1D_stop \
-jobs 1 \
-virtvec
