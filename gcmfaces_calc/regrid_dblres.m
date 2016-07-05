function [P]=regrid_dblres(P,pType,nDblRes);
%object : double the resolution (only along 3rd dimension for now)
%         for a variable P (extensive or intensive) a number of times.
%input :  P is the variable of interest
%         pType is 'extensive' or 'intensive'
%         nDblRes is the number of resolution doublings.
%output : P is the input variable but with 2^nDblRes resolution

gcmfaces_global;

for ii=1:nDblRes;
    %start with repmat
    tmp1=repmat(P,[1 1 2]);
    nn=size(P{1},3);
    tmp1(:,:,1:2:2*nn)=P;
    tmp1(:,:,2:2:2*nn)=P;
    %interpolate (in grid point space)
    tmp2=NaN*tmp1;
    tmp2(:,:,2:2:2*nn-2)=3/4*P(:,:,1:nn-1)+1/4*P(:,:,2:nn);
    tmp2(:,:,3:2:2*nn-1)=1/4*P(:,:,1:nn-1)+3/4*P(:,:,2:nn);
    tmp1(~isnan(tmp2))=tmp2(~isnan(tmp2));
    %if extensive then we want to conserve the sum over grid points
    if strcmp(pType,'extensive'); tmp1=tmp1/2; end;
    %overwite P
    P=tmp1;
end;

