#!/bin/bash

# Check whether the file subjList.txt exists; if not, create it
if [ ! -f subjList.txt ]; then
    ls | grep ^sub- > subjList.txt
fi

if [ ! -f subjList.txt ]; then
    find . -maxdepth 1 -type d -name 'sub-*' | sed 's/.*\///' | sort > subjList.txt
fi # this works best

# Loop over all subjects and format timing files into FSL format
for subj in `cat subjList.txt`; do
    derivatives_dir="derivatives/$subj/func"
    cd "$subj/func"
    echo "Processing subject: $subj"
    
    cat ${subj}_task-scap_events.tsv | awk '{if ($3 >= 1 && $3 <= 6) {print $1}}' > "../../$derivatives_dir/{$subj}_low_WM.txt"
    cat ${subj}_task-scap_events.tsv | awk '{if ($3 >= 7 && $3 <= 12) {print $1}}' > "../../$derivatives_dir/{$subj}_high_WM.txt"

    # Now convert to AFNI format
    echo "Converting to AFNI format..."
    timing_tool.py -fsl_timing_files "../../$derivatives_dir/{$subj}_low_WM.txt" -write_timing "../../$derivatives_dir/{$subj}_low_WM.txt"
    timing_tool.py -fsl_timing_files "../../$derivatives_dir/{$subj}_high_WM.txt" -write_timing "../../$derivatives_dir/{$subj}_high_WM.txt"

    cd ../..
done
