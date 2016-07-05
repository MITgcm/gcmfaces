function [fldOut,area]=calc_mskmean_T(fldIn,mask,fldType);
% CALC_MSKMEAN_T(budgIn,mask,fldType) 
%    computes average over a region (mask) of fldIn (or its fields recursively).
%    If fldType is 'intensive' (default) then fldIn is mutliplies by RAC.

gcmfaces_global;

if isempty(who('fldType')); fldType='intensive'; end;

if isa(fldIn,'struct');
  list0=fieldnames(fldIn);
  fldOut=[];
  for vv=1:length(list0);
    tmp1=getfield(fldIn,list0{vv});
    if isa(tmp1,'gcmfaces');
      [tmp2,area]=calc_mskmean_T(tmp1,mask,fldType);
      fldOut=setfield(fldOut,list0{vv},tmp2);
    end;
  end;
  return;
end;

nr=size(fldIn{1},3);
nr2=size(mask{1},3);
if nr2~=nr; mask=repmat(mask,[1 1 nr]); end;
mask(mask==0)=NaN; mask(isnan(fldIn))=NaN;
areaMask=repmat(mygrid.RAC,[1 1 nr]).*mask;
if strcmp(fldType,'intensive');
  fldOut=nansum(fldIn.*areaMask,0)./nansum(areaMask,0);
  area=nansum(areaMask,0);
else;
  fldOut=nansum(fldIn.*mask,0)./nansum(areaMask,0);
  area=nansum(areaMask,0);
end;


