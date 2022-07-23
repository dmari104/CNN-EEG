
import mne
import numpy as np
import assets._segmentation as _segmentation


def artifacts(mapped_segments):
    copy_segments = mapped_segments.copy()
    # Get indices of ignored segments
    ids = [e[2] for e in copy_segments.events]
    idx_ignore = [id for id, id_ in enumerate(ids) if id_ == 2]
    # Drop ignored segments
    copy_segments.drop(idx_ignore)
    # Get indices of nonartifacts
    idx_nonartifacts = [id for id, id_ in enumerate(copy_segments.events) if id_[2] == 1]
    # Drop nonartifacts
    artifacts = copy_segments.drop(idx_nonartifacts)

    return artifacts


def nonartifacts(mapped_segments):
    copy_segments = mapped_segments.copy()
    # Get indices of ignored segments
    ids = [e[2] for e in copy_segments.events]
    idx_ignore = [id for id, id_ in enumerate(ids) if id_ == 2]
    # Drop ignored segments
    copy_segments.drop(idx_ignore)
    # Get indices of artifacts
    idx_artifacts = [id for id, id_ in enumerate(copy_segments.events) if id_[2] == 0]
    # Drop artifacts
    nonartifacts = copy_segments.drop(idx_artifacts)

    return nonartifacts


def map(Raw, segments, windowSize, cutoffLength):
    annotations_onsets = Raw.annotations.onset
    annotations_durations = Raw.annotations.duration
    event_onsets = np.array([onset[0] / Raw.info['sfreq'] for onset in segments.events])
    mapped_segments = segments.copy()

    for i, event_onset in enumerate(event_onsets):
        for onset, duration in zip(annotations_onsets, annotations_durations):
            # if segments within the annotation interval or intersects it to the right or left
            # or annotation interval is within the segment
            if (event_onset >= onset and event_onset + windowSize <= onset + duration) or \
                    (
                            event_onset >= onset and event_onset + windowSize >= onset + duration and event_onset < onset + duration) or \
                    (
                            event_onset <= onset and event_onset + windowSize > onset and event_onset + windowSize <= onset + duration) or \
                    (
                            event_onset <= onset and event_onset + windowSize > onset and event_onset + windowSize > onset + duration):

                # Determine length of the intersection
                if onset <= event_onset:
                    start = event_onset
                else:
                    start = onset

                if onset + duration >= event_onset + windowSize:
                    end = event_onset + windowSize
                else:
                    end = onset + duration

                intersection_length = end - start

                # Call segments an artifact
                if intersection_length >= cutoffLength:
                    mapped_segments.events[i][2] = 0
                    break
                # Call segments an artifact
                elif intersection_length < cutoffLength and duration <= cutoffLength:
                    mapped_segments.events[i][2] = 0
                    break
                # Ignore segment
                elif intersection_length < cutoffLength and duration > cutoffLength:
                    mapped_segments.events[i][2] = 2
            else:
                continue
    mapped_segments.event_id = {'nonartifact': 1, 'artifact': 0, 'ignored': 2}

    return mapped_segments