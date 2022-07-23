function items = sh_removeParents(items)
    removeIndices = [];
    for itemIdx = 1 : length(items)
        if ~isempty(strmatch(items(itemIdx).name, '.')) || ~isempty(strmatch(items(itemIdx).name, '..'))
            removeIndices = [removeIndices, itemIdx];
        end
    end
    keepIndices = setdiff(1:length(items), removeIndices);
    items = items(keepIndices);
end