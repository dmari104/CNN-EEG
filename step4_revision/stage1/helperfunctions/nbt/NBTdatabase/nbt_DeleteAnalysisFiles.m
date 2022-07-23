% Copyright (C) 2011 Neuronal Oscillations and Cognition group, Department of Integrative Neurophysiology, Center for Neurogenomics and Cognitive Research, Neuroscience Campus Amsterdam, VU University Amsterdam.
function nbt_DeleteAnalysisFiles(startpath,enterSubDir)
nbt_fileLooper(startpath,'mat','analysis',@delete,enterSubDir);
end