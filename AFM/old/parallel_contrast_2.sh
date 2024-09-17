path_der="derivatives"

function get_contrast {
    p_array="$1"
    sub_id=$(basename "$p_array" | grep -oP 'sub-\d+')
    e_array="$path_der/${sub_id}/func/mod_${sub_id}_mean_cope_resampled_ts_1vol.npy"
    
    echo -e "############# Processing $sub_id, $p_array $e_array \n"
    
    python ../code/AFM/get_contrast_2.py $p_array $e_array

}

export -f get_contrast

find "$path_der" -type f -name 'taskPredMatrix_sub-*_*.npy' > "$path_der/p_array_files.txt"
sort "$path_der/p_array_files.txt" -o "$path_der/p_array_files.txt"

N=1
(
for ii in $(cat "$path_der/p_array_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   get_contrast "$ii" &
done
)
rm "$path_der/p_array_files.txt"