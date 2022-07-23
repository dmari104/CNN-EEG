
import numpy as np
import math
from pathlib import Path
import scipy
import scipy.fft
import scipy.stats
from scipy.spatial import KDTree
from joblib import Parallel, delayed
import multiprocessing
import matplotlib


SELECTED_CHANNELS = ['Fp1', 'Fp2', 'F3', 'F4', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2', 'F7', 'F8', 'T3', 'T4', 'T5', 'T6',
                     'Fz', 'Cz', 'Pz']

def _wavelet_fft(frequencies, fwhm, nConv, wavtime):

    """
        Returns FFTs of complex Morlet wavelet

        Parameters
        ----------
        frequencies (numpy array): frequency bins
        fwhm (numpy array): Full-width at half maximum parameter values which defines time resolution
        nConv (int): Length of the output. If n is smaller than the length of the input, the input is cropped.
                If it is larger, the input is padded with zeros.
        wavtime (numpy array): Wavelet time-series
    """

    waveletFFT = np.zeros([len(frequencies), nConv], dtype=np.complex_)
    for i, freq, width in zip(range(len(frequencies)), frequencies, fwhm):
        # Define gaussian
        gwin = np.exp((-4 * math.log(2) * (wavtime ** 2)) / (width ** 2))
        # Constructr a complex Morlet wavelet
        cmw = np.exp(1j * 2 * np.pi * freq * wavtime) * gwin
        # FFT of the wavelet
        tempX = scipy.fft.fft(cmw, nConv)
        norm = tempX[np.where(np.abs(tempX) == np.max(np.abs(tempX)))[0][0]]
        # Normalize
        waveletFFT[i, :] = tempX / norm

    return waveletFFT


def _wavelet_convolution(waveletFFT, segmentsRaw, halfwav, nFreq, donwsampling=100):
    """
        Returns Wavelet convolution results (Z-score-normalized time-frequency power values of EEG segments)

        Parameters
        ----------
        waveletFFT (numpy 2D array): FFT of a complex Morlet wavelet
        segmentsRaw (MNE Epochs): Segments/epochs of an EEG recording as MNE Epochs object
        halfwav (int): Index of the center point of the wavelet time-series
        nFreq (int): Number of frequency bins
        donwsampling: in Hz

        Returns
        -------
        out (2D list): Z-score-normalized time-frequency power values flattened across all channels
            for each EEG segment/epoch
    """

    # Window size in seconds
    windowSize = segmentsRaw.times[-1] + 1/segmentsRaw.info['sfreq']

    # Donwsampling step in seconds
    step = 1 / donwsampling

    # Create time bins for downsampling within the length of the window
    timeBins = np.arange(0.0, windowSize, step)

    nChan = len(segmentsRaw.ch_names)

    # Create indexing for times to look up the nearest neighbors of any point
    kdtree = KDTree(np.reshape(segmentsRaw.times, (np.shape(segmentsRaw.times)[0], 1)))

    # Find indices of the nearest points in kd-tree of times to time bin points
    _, inds = kdtree.query(np.reshape(timeBins, (np.shape(timeBins)[0], 1)))
    selectedTimeBins = inds

    num_cores = multiprocessing.cpu_count()
    print('# cores {}'.format(num_cores))
    def processInput(input):
        data = input.get_data()[0]
        tf = np.zeros([nFreq * nChan, len(timeBins)])
        rowIdx = 0
        for n in range(nChan):
            # FFT of the signal
            dataX1 = scipy.fft.fft(data[n], len(waveletFFT[0]))
            for j in range(nFreq):
                # print(n, j, waveletFFT[j, :])
                as1 = scipy.fft.ifft(waveletFFT[j, :] * dataX1)
                as1 = as1[halfwav:len(as1) - halfwav]
                tf[rowIdx, :] = (np.abs(as1[selectedTimeBins])) ** 2
                rowIdx = rowIdx + 1

        return scipy.stats.zscore(tf, axis=None)  # Z-score nomralize

    TFs = Parallel(n_jobs=num_cores, backend='threading')(delayed(processInput)(segmentsRaw[k])
                                                          for k in range(len(segmentsRaw)))
    TFs = list(TFs)

    return TFs


def _to_intensity(segmentTFs):
    # Normalize each segment across all channels
    return [(tf - np.min(tf)) / (np.max(tf) - np.min(tf)) for tf in segmentTFs]


def _to_uint8(intensityTFs):
    return [(ints / np.max(ints))*255 for ints in intensityTFs]


def segmentTF(segmentsRaw):
    """
        Returns values of normalized power in time and frequency for each segment/epoch of and EEG recording

        Parameters
        ----------
        segmentsRaw (mne.Epochs): Epochs/segments of the EEG recording

        Returns
        -------
        out (uint8): Time-frequency images for eqch segment/epoch of the EEG recording
    """

    # Checks (segmentsRaw type, number of channels = 19, segmentsRaw contain segments)

    # Parameters for Wavelet convolution
    minFreq = 0.5  # Hz
    maxFreq = 45  # Hz
    nFreq = 45
    minFWHM = 0.2  # time resolution in seconds
    maxFWHM = 1.2  # time resolution in seconds

    # Get all frequencies
    frequencies = np.logspace(math.log10(minFreq), math.log10(maxFreq), nFreq)
    # Get time resolution for each frequency
    fwhm = np.logspace(math.log10(maxFWHM), math.log10(minFWHM), nFreq)

    # Wavelet parameters
    t = 4  # length in seconds
    # Wavelet centered at 0
    wavtime = np.linspace(-2, 2, t * int(segmentsRaw.info['sfreq']) + 1)
    # Find the center of the wavelet (index)
    halfwav = list(np.where(wavtime == 0)[0])[0]

    # Convolution parameters
    nWave = len(wavtime)
    nData = len(segmentsRaw.times)
    nConv = nWave + nData - 1

    # Complex Morlet wavelet FFTs
    cmwFFT = _wavelet_fft(frequencies, fwhm, nConv, wavtime)

    # Pick 19 standard channels
    segmentsRaw.pick_channels(SELECTED_CHANNELS, ordered=True)

    # A list of time-frequency normalized power of EEG segments of the recording
    segmentTFs = _wavelet_convolution(cmwFFT, segmentsRaw, halfwav, len(frequencies))

    # Convert to intensities
    intensityTFs = _to_intensity(segmentTFs)  # values between 0 and 1
    # Convert to uint8 image format
    intensityTFs = _to_uint8(intensityTFs)

    ######################## Only use to generate example data
    # Reshape to (nsegments, nchannels, nfrequencies, ntimes)
    # intensityTFs_reshaped = np.reshape(np.array(intensityTFs),
    #                                    (np.shape(np.array(intensityTFs))[0],
    #                                     len(segmentsRaw.ch_names),
    #                                     len(frequencies), np.shape(np.array(intensityTFs))[2]))

    return intensityTFs