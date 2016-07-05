function [vec]=gcmfaces_subset(msk,fld,applyMsk);
%object:    extract the subset of points from fld(.*msk) such that msk~=0
%inputs:    msk is the gcmfaces subdomain mask (one vertical level)
%           fld is the complete field (gcmfaces or array version)
%optional:  applyMsk is a flag that stated whether to multiply with 
%               msk (applyMsk==1; default) or not (applyMsk==0);
%output:    vec is the subset field 
%
%note:      - if fld is an array, then it must be a result of convert2array
%           - for velocity subsets, msk may be -1 or +1, depending on
%           directionality, e.g. when msk delineates a transport section.

if isempty(whos('applyMsk')); applyMsk=1; end;

if isa(fld,'gcmfaces'); fld=convert2array(fld); end;
nn=size(fld); nn=[nn ones(1,4-length(nn))];
fld=reshape(fld,nn(1)*nn(2),nn(3)*nn(4));

msk=convert2array(msk); msk=msk(:);

ii=find(msk~=0&~isnan(msk)); mm=length(ii);
if mm==0;
    vec=zeros(1,nn(3),nn(4));
else;
    if applyMsk; 
        vec=fld(ii,:).*(msk(ii)*ones(1,nn(3)*nn(4)));
    else; 
        vec=fld(ii,:);
    end;
    vec=reshape(vec,[mm nn(3) nn(4)]);
end;


