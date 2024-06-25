path_der="derivatives/"
'derivatives/output_AFM_low_wm_3000_30.npy/taskPredMatrix_sub-10290_low_wm_3000_30.npy.npy'

function get_contrast {
    p_low_1500="$1"
    sub_id=$(basename "$p_low_1500" | grep -oP 'sub-\d+')
    n_seed=$(basename "$p_low_1500" | grep -oP '(?<=_)\d+(?=\.npy)')
    
    p_low_3000="${p_low_1500%output_AFM*}output_AFM_low_wm_3000_${n_seed}/taskPredMatrix_${sub_id}_low_wm_3000_${n_seed}.npy"
    p_low_4500="${p_low_1500%output_AFM*}output_AFM_low_wm_4500_${n_seed}/taskPredMatrix_${sub_id}_low_wm_4500_${n_seed}.npy"
    p_high_1500="${p_low_1500%output_AFM*}output_AFM_high_wm_1500_${n_seed}/taskPredMatrix_${sub_id}_high_wm_1500_${n_seed}.npy"
    p_high_3000="${p_low_1500%output_AFM*}output_AFM_high_wm_3000_${n_seed}/taskPredMatrix_${sub_id}_high_wm_3000_${n_seed}.npy"
    p_high_4500="${p_low_1500%output_AFM*}output_AFM_high_wm_4500_${n_seed}/taskPredMatrix_${sub_id}_high_wm_4500_${n_seed}.npy"

    e_low_1500="${p_low_1500%output_AFM*}${sub_id}/func/low_wm_1500_${sub_id}_ts_1vol.npy"
    e_low_3000="${p_low_1500%output_AFM*}${sub_id}/func/low_wm_3000_${sub_id}_ts_1vol.npy"
    e_low_4500="${p_low_1500%output_AFM*}${sub_id}/func/low_wm_4500_${sub_id}_ts_1vol.npy"
    e_high_1500="${p_low_1500%output_AFM*}${sub_id}/func/high_wm_1500_${sub_id}_ts_1vol.npy"
    e_high_3000="${p_low_1500%output_AFM*}${sub_id}/func/high_wm_3000_${sub_id}_ts_1vol.npy"
    e_high_4500="${p_low_1500%output_AFM*}${sub_id}/func/high_wm_4500_${sub_id}_ts_1vol.npy"

    if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then

        echo -e "############# Processing $sub_id... \n"
        python ../code/get_contrast.py $p_low_1500 $p_low_3000 $p_low_4500 $p_high_1500 $p_high_3000 $p_high_4500 $e_low_1500 $e_low_3000 $e_low_4500 $e_high_1500 $e_high_3000 $e_high_4500
        
    else
        echo -e "\n Subject $sub_id is excluded. Skipping..."
    fi
}

export -f get_contrast

find "$path_der" -type f -name '*taskPredMatrix_*low_wm_1500_30.npy' > "$path_der/sing_files.txt"

N=120
(
for ii in $(cat "$path_der/sing_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   get_contrast "$ii" &
done
)
rm "$path_der/sing_files.txt"
