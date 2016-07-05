function [Vq]=gcmfaces_interp_1d(xDim,X,V,Xq);
%[Vq]=GCMFACES_INTERP_1D(xDim,X,V,Xq);
%  Linearly interpolates a field (V; array or gcmfaces) along a 
%  selected dimension (xDim) from locations specified in 
%  vector X to locations specified in vector Xq 

gcmfaces_global;

%change format if needed
isagcmfaces=isa(V,'gcmfaces');
if isagcmfaces; V=convert2gcmfaces(V); end;

%move interpolation dimension to first
ndim=length(size(V));
tmp1=circshift([1:ndim],[0 1-xDim]);
V=permute(V,tmp1);
if size(X,1)==1; X=X'; end;
if size(Xq,1)==1; Xq=Xq'; end;

%the interpolation itself
Kq=interp1(X,[1:length(X)]',Xq,'linear');
Kqne=interp1(X,[1:length(X)]',Xq,'nearest','extrap');

%use bilinear; then extrapolate with nearest neighbor 
Vq=NaN*repmat(V(1,:,:),[length(Xq) 1 1]);
for kk=1:length(Xq);
    if ~isnan(Kq(kk));
        k0=floor(Kq(kk));
        k1=min(k0+1,length(X));
        a0=Kq(kk)-k0;
        tmp1=(1-a0)*V(k0,:,:)+a0*V(k1,:,:);
    else;
        tmp1=NaN*V(1,:,:);
    end;
    tmp2=V(Kqne(kk),:,:);
    tmp1(isnan(tmp1))=tmp2(isnan(tmp1));
    Vq(kk,:,:)=tmp1;
end;

%move interpolation dimension to first
tmp1=circshift([1:ndim],[0 xDim-1]);
Vq=permute(Vq,tmp1);

%change format if needed
if isagcmfaces; Vq=convert2gcmfaces(Vq); end;

