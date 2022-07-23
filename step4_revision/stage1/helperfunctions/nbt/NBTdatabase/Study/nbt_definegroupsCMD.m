function nbt_definegroupsCMD
%define groups on the command line
global NBTstudy
if(~isa(NBTstudy,'nbt_Study'))
    NBTstudy = nbt_Study;
end

nrGrp = input('How many groups do you want to define? ');
grpIdx = length(NBTstudy.groups);
for i=1:nrGrp
    grpIdx = grpIdx + 1;
    NBTstudy.groups{grpIdx} = nbt_Group.defineGroup(nbt_Group);
    NBTstudy.groups{grpIdx}.grpNumber = grpIdx;
end
end