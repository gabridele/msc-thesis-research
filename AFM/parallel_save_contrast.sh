path_der="derivatives/"

function get_contrast {
    e_low_1500="$1"
    sub_id=$(basename "$e_low_1500" | grep -oP 'sub-\d+')

    e_low_3000="${e_low_1500%1500*}3000_${sub_id}_ts_1vol.npy"
    e_low_4500="${e_low_1500%1500*}4500_${sub_id}_ts_1vol.npy"
    e_high_1500="${e_low_1500%low*}high_wm_1500_${sub_id}_ts_1vol.npy"
    e_high_3000="${e_low_1500%low*}high_wm_3000_${sub_id}_ts_1vol.npy"
    e_high_4500="${e_low_1500%low*}high_wm_4500_${sub_id}_ts_1vol.npy"

    if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then

        echo -e "############# Processing $sub_id... \n"
        python ../code/AFM/save_emp_contrast.py $e_low_1500 $e_low_3000 $e_low_4500 $e_high_1500 $e_high_3000 $e_high_4500
        
    else
        echo -e "\n Subject $sub_id is excluded. Skipping..."
    fi
}

export -f get_contrast

find "$path_der" -type f -name 'low_wm_1500_*_ts_1vol.npy' > "$path_der/sing_files.txt"
N=120
(
for ii in $(cat "$path_der/sing_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   get_contrast "$ii" &
done
)
rm "$path_der/sing_files.txt"
