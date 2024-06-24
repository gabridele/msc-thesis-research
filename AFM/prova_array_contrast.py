
import numpy as np
from scipy.stats import spearmanr

p_low_1500 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/output_AFM_low_wm_1500_2/taskPredMatrix_sub-10171_low_wm_1500_2.npy" 
p_high_4500 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/output_AFM_high_wm_4500_2/taskPredMatrix_sub-10171_high_wm_4500_2.npy" 
p_high_3000 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/output_AFM_high_wm_3000_2/taskPredMatrix_sub-10171_high_wm_3000_2.npy" 
p_low_4500 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/output_AFM_low_wm_4500_2/taskPredMatrix_sub-10171_low_wm_4500_2.npy" 
p_high_1500 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/output_AFM_high_wm_1500_2/taskPredMatrix_sub-10171_high_wm_1500_2.npy" 
p_low_3000 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/output_AFM_low_wm_3000_2/taskPredMatrix_sub-10171_low_wm_3000_2.npy"

p_low_1500 = np.load(p_low_1500)
p_low_3000 = np.load(p_low_3000)
p_low_4500 = np.load(p_low_4500)
p_high_1500 = np.load(p_high_1500)
p_high_3000 = np.load(p_high_3000)
p_high_4500 = np.load(p_high_4500)

p_low_avg = (p_low_1500 + p_low_3000 + p_low_4500) / 3

p_high_avg = (p_high_1500 + p_high_3000 + p_high_4500) / 3

p_diff = p_low_avg - p_high_avg

e_low_1500 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/sub-10171/func/low_wm_1500_sub-10171_ts_1vol.npy"
e_high_4500 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/sub-10171/func/high_wm_4500_sub-10171_ts_1vol.npy" 
e_high_3000 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/sub-10171/func/high_wm_3000_sub-10171_ts_1vol.npy"  
e_low_4500 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/sub-10171/func/low_wm_4500_sub-10171_ts_1vol.npy" 
e_high_1500 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/sub-10171/func/high_wm_1500_sub-10171_ts_1vol.npy" 
e_low_3000 = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/derivatives/sub-10171/func/low_wm_3000_sub-10171_ts_1vol.npy"

e_low_1500 = np.load(e_low_1500)
e_low_3000 = np.load(e_low_3000)
e_low_4500 = np.load(e_low_4500)
e_high_1500 = np.load(e_high_1500)
e_high_3000 = np.load(e_high_3000)
e_high_4500 = np.load(e_high_4500)

e_low_avg = (e_low_1500 + e_low_3000 + e_low_4500) / 3

e_high_avg = (e_high_1500 + e_high_3000 + e_high_4500) / 3

e_diff = e_low_avg - e_high_avg
p_diff = p_diff[:, :, 0]
print(p_diff.shape)
spearman_corr, spearman_p_val = spearmanr(p_diff[0], e_diff[0], nan_policy='raise')

print(spearman_corr)
print(spearman_p_val)
