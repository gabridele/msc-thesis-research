path_der="derivatives/preproc_dl"

function get_contrast {
    p_array="$1"
    sub_id=$(basename "$p_array" | grep -oP 'sub-\d+')
    n_seed=$(basename "$p_array" | grep -oP '(?<=_)\d+(?=\.npy)')
    e_array="$path_der/${sub_id}/scap.feat/${sub_id}_mean_cope_resampled_ts_1vol.npy"
    
    echo -e "############# Processing $sub_id... \n"
    echo "$p_array, $e_array"
    python ../code/AFM/get_contrast_2.py $p_array $e_array

}

export -f get_contrast

find "$path_der" -type f -name 'taskPredMatrix_sub-*_*.npy' > "$path_der/p_array_files.txt"

N=140
(
for ii in $(cat "$path_der/p_array_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   get_contrast "$ii" &
done
)
rm "$path_der/p_array_files.txt"