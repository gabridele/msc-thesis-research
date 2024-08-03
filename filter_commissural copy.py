import glob
import re
import os
from dipy.io.streamline import load_tractogram
from dipy.tracking.streamline import ArraySequence

def find(directory):
    # Regular expression to match *roi*.txt but not *roi*only_comm.txt
    pattern_include = re.compile(r'.*roi.*\.tck')
    pattern_exclude = re.compile(r'.*roi.*only_comm\.tck')
    # Regular expression to extract subject ID
    pattern_sub_id = re.compile(r"sub-(\d+)_")
    
    matching_files_with_ids = []
    
    for filename in os.listdir(directory):
        if pattern_include.match(filename) and not pattern_exclude.match(filename):
            subject_id_match = pattern_sub_id.search(filename)
            if subject_id_match:
                subject_id = subject_id_match.group(1)
                matching_files_with_ids.append((filename, subject_id))
            else:
                matching_files_with_ids.append((filename, None))
    
    return matching_files_with_ids

def filter_sub(sub):
    sub_id = sub[1]
    # sub: path to folder derivatives for a given subject
    b0 = glob.glob(os.path.join(os.getcwd(), f'{sub_id}/dwi/*b0_masked.nii.gz'))
    
    # Find ROI files and extract subject IDs
    roi_files = sub[0]
    
    # Filter only the file names
    #files = [os.path.join(sub, 'dwi', file) for file, _ in roi_files]
    #files.sort()  # Sort the files
    
    n_streams_per_roi = []
    
    #for file in files:
    print("processing:", roi_files)
    streams = load_tractogram(roi_files, b0[0])
    print('b0:', b0)
    tracto = streams.streamlines
    array_seq = ArraySequence()
    
    for stream in tracto:
        if (stream[0][0] * stream[-1][0] < 0) and (stream[0][1] * stream[-1][1] > 0) and (stream[0][2] * stream[-1][2] > 0):
            array_seq.append(stream, cache_build=True)
            array_seq.finalize_append()
    
    n_streams_per_roi.append(len(array_seq))
        
        # Uncomment these lines if you want to save the filtered tractograms
        # out_name = file.replace('.tck', '_only_comm.tck')
        # print(out_name)
        # trac = StatefulTractogram(array_seq, reference=b0[0], space=Space.RASMM)
        # save_tck(trac, out_name)
        # print('done processing', file)
    
    return n_streams_per_roi

# Example usage:
# Replace 'path/to/subject/folder' with the actual path to the subject's folder

subject_folder = find(os.getcwd())
for sub in subject_folder:
    n_streams = filter_sub(sub)
print(n_streams)