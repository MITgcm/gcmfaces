function [fldOut]=matLoadFix(fldIn);
%It seems that saving a gcmfaces object to a ".mat" file and then 
%reloading it to memory re-orders the fields. This then leads to 
%failures during gcmfaces object manipulations. This function test 
%whether the ordering of fields is correct and fixes it if needed.
%
%example:
%
% fld=mygrid.XC; fldPre=fld;
% save fldMat.mat fld;
% fieldnames(fld)
%
% load fldMat.mat;
% fieldnames(fld)
% fld+fld;%creates an error
%
% fld=matLoadFix(fld);
% fieldnames(fld)
% fld+fld;%should work fine

gcmfaces_global;

tmp1=fieldnames(fldIn);
tmp2=fieldnames(mygrid.XC);

if isequaln(tmp1,tmp2);
  fldOut=fldIn;
else;
  fldOut=gcmfaces(fldIn.nFaces);
  for iFace=1:fldIn.nFaces;
    fldOut{iFace}=getfield(fldIn,['f' num2str(iFace)]);
  end;
end;

