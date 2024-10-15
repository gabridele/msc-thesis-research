# script to compute correlation between brain regions from rsfmri data. Aka getting the FC matrix

from nilearn import image, regions
import numpy as np
import os
from scipy import stats
import glob
from multiprocessing import Pool

# def extract_ts(subject_name):

#     sub_id = subject_name.split('/')[-3]

#     ts, labels = regions.img_to_signals_labels(
#         image.load_img(subject_name, dtype='float64'),
#         image.load_img(path_to_atlas),
#         mask_img=None,
#         background_label=0
#     )

#     ts = ts.T
#     ts[ts == 0] = np.nan
#     # get FC matrix via Pearson correlation
#     correlation_result = stats.pearsonr(ts)
    
#     # extract correlation matrix
#     correlation_matrix = correlation_result.correlation

#     # set diagonal to 0
#     np.fill_diagonal(correlation_matrix, 0)
#     correlation_matrix[correlation_matrix == np.nan] = 0
#     output_path = os.path.join(out_dir, sub_id, 'func', sub_id + '_FC_correlation_matrix.npy')
#     np.save(output_path, correlation_matrix)

def extract_ts(subject_name):

    sub_id = subject_name.split('/')[-3]

    ts, labels = regions.img_to_signals_labels(
        image.load_img(subject_name, dtype='float64'),
        image.load_img(path_to_atlas),
        mask_img=None,
        background_label=0
    )

    ts = ts.T
    
    # get FC matrix via Pearson correlation
    correlation_matrix = np.corrcoef(ts)

    # set the diagonal to 0
    np.fill_diagonal(correlation_matrix, 0)

    output_path = os.path.join(out_dir, sub_id, 'func', sub_id + '_FC_correlation_matrix.npy')
    np.save(output_path, correlation_matrix)
    
def main():
    
    global path_to_atlas
    global out_dir

    path_to_atlas = os.path.join(os.getcwd(), 'derivatives', 'templates', 'Schaefer2018_400Parcels_Tian_Subcortex_S4_2mm_2009c_NLinAsymm.nii.gz')

    out_dir = os.path.join(os.getcwd(), 'derivatives')
   
    single_files = os.path.join(os.getcwd(), 'derivatives', 'sub*', 'func', 'sub-*_regressed_smoothed_resampled.nii.gz')

    subjects = sorted(glob.glob(single_files))

    with Pool(processes = 140) as pool:
        pool.map(extract_ts, subjects)

if __name__ == '__main__':
    main()

