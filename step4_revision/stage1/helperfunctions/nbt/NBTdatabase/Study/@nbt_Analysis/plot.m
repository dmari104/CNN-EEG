function plot(AnalysisObj)
%Plotting Analysis objects depending on biomarker classes
disp('break')
%First we sort into the different classes:
% QBiomarkers

for j=1:size(AnalysisObj.data,2)
    if ~isempty(AnalysisObj.data{j}) non_empty_ind = j; end
end

QBidx = nbt_searchvector(AnalysisObj.data{non_empty_ind}.classes,{'nbt_QBiomarker'});
if(~isempty(QBidx))
   nbt_plotQbiomarkerTable(AnalysisObj, QBidx) 
end

% SignalBiomarkers
SBidx = nbt_searchvector(AnalysisObj.data{non_empty_ind}.classes,{'nbt_SignalBiomarker'});



end
