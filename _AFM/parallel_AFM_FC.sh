#####
# script to run AFM with FC parallelizing over multiple siubjects
# adjust N to your likings
#####

path_der="derivatives"

function run_AFM_FC {
    arg1="$1"
    sub_id=$(basename "$arg1" | grep -oP 'sub-\d+')
    arg2="$path_der/${sub_id}/func/processed_${sub_id}_mean_cope_resampled_ts_1vol.npy"

    # need to have a file with list of subjects that are retained after exclusion process
    if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
        echo -e "############# $sub_id, $arg1, $arg2 \n"

        python ../code/AFM/AFM_run_FC.py $arg1 $arg2
    else
        echo -e "\n Subject $sub_id is excluded. Skipping..."
    fi

}
export -f run_AFM_FC

find "$path_der" -type f -name 'processed_functional_connectivity_sub-*.npy' > "$path_der/FC_mtrx_files.txt"

N=140
(
for ii in $(cat "$path_der/FC_mtrx_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   run_AFM_FC "$ii" &
done
)
rm "$path_der/FC_mtrx_files.txt"