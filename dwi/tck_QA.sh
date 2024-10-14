# script to get homotopic connections of three different brain areas (frontal, motor, visual). For visual quality check. Approach later discarded in favor of counting commissural fibers 

path_der='derivatives/'

function QA_tck {
  input_tck="$1"
  sub_id=$(basename "$input_tck" | grep -oP 'sub-\d+')
  input_txt="${input_tck%tracks_5000000mio.tck}Schaefer2018_400Parcels_Tian_Subcortex_S4_1mm_5000000mio_out_assignments.txt"
  output_motor="${input_tck%tracks_5000000mio.tck}motor_tracts.tck"
  output_vis="${input_tck%tracks_5000000mio.tck}vis_tracts.tck"
  output_front="${input_tck%tracks_5000000mio.tck}front_tracts.tck"
  merged="${input_tck%tracks_5000000mio.tck}merged_tracts.tck"

  echo -e "##################"
  echo -e "now processing $sub_id"

  connectome2tck $input_tck $input_txt $output_motor -nodes 324,120 -exclusive -files single
  connectome2tck $input_tck $input_txt $output_vis -nodes 66,267 -exclusive -files single
  connectome2tck $input_tck $input_txt $output_front -nodes 238,443 -exclusive -files single
  
  tckedit $output_motor $output_vis $output_front $merged

  echo -e "files for $sub_id successfully saved"
}

export -f QA_tck

find "$path_der" -type f -name '*tracks_5000000mio.tck' > "$path_der/mio_tck.txt"

N=20
(
for ii in $(cat "$path_der/mio_tck.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   QA_tck "$ii" &
done
)
"$path_der/mio_tck.txt"