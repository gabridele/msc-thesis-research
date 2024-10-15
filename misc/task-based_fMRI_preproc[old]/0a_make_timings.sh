#!/bin/bash

# pwd has to be dataset's

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