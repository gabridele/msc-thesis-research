from nilearn import image
from nilearn import regions
import numpy as np
import os
import glob
import time
from multiprocessing import Pool
import scipy.io as sio

def extract_ts(subject_name):

   ts,labels=regions.img_to_signals_labels(image.load_img(subject_name,dtype='float64'), image.load_img(path_to_atlas), mask_img=None, background_label=0)
   
   ts = ts[:, :1]
   ts = ts.T
   sub_name_no_ending=('.').join(subject_name.split('/')[-1].split('.')[:-2])
   
   np.save(out_dir+'/'+sub_name_no_ending,'_1vol_',ts)


def main():


   global path_to_atlas

   path_to_atlas = os.getcwd()+'/derivatives/templates/'+'Schaefer2018_400Parcels_Tian_Subcortex_S4_1mm_2009c_NLinAsymm.nii.gz'
   
   print(path_to_atlas)
   
   global out_dir
   
   out_dir = os.getcwd()+'/derivatives/'
   print(out_dir)
   
   #path nella cartella coi dati func
   single_files = os.getcwd()+'/derivatives/sub*/func/*_2vol_ts.nii.gz'
   
   print(single_files)
   
   subjects = sorted(glob.glob(single_files))
   
   print(subjects)
   
   pool = Pool(processes=2)

   pool.map(extract_ts, subjects)
 
# If called from the command line, run main()
if __name__ == '__main__':
   main()

