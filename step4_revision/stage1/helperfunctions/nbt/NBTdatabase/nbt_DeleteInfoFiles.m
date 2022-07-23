% Copyright (C) 2011 Neuronal Oscillations and Cognition group, Department of Integrative Neurophysiology, Center for Neurogenomics and Cognitive Research, Neuroscience Campus Amsterdam, VU University Amsterdam.
function nbt_DeleteInfoFiles(startpath)
nbt_fileLooper(startpath,'mat','info',@delete,enterSubDir);
end