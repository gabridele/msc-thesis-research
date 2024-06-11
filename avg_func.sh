
3dcalc -a "$input" -expr '(a == 1) * a' -prefix low_wm_condition1500.nii.gz
3dcalc -a "$input" -expr '(a == 4) * a' -prefix low_wm_condition3000.nii.gz
3dcalc -a "$input" -expr '(a == 7) * a' -prefix low_wm_condition4500.nii.gz

3dMean -prefix avg_low_wm.nii.gz low_wm_condition*.nii.gz

3dcalc -a "$input" -expr '(a == 10) * a' -prefix high_wm_condition1500.nii.gz
3dcalc -a "$input" -expr '(a == 13) * a' -prefix high_wm_condition3000.nii.gz
3dcalc -a "$input" -expr '(a == 16) * a' -prefix high_wm_condition4500.nii.gz

3dMean -prefix avg_high_wm.nii.gz high_wm_condition*.nii.gz

rm low_wm_condition*.nii.gz
rm high_wm_condition*.nii.gz

3dcalc -a avg_low_wm.nii.gz -b avg_high_wm.nii.gz -expr 'a - b' -prefix diff_high_minus_low.nii.gz
