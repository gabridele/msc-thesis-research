import numpy as np
import glob

dir = "/home/gabridele/Desktop/irbio_folder/spreading_dynamics_clinical/HC_emp"

#list all files with glob
files = glob.glob(dir + 'emp*.npy')

#load files and stack them into single array
arrays = [np.load(file) for file in files]
print(arrays)
mean_array = np.mean(arrays, axis=0)

#save mean array to new file
output = "avgd_emp_hc.npy"
np.save(dir + output, mean_array)