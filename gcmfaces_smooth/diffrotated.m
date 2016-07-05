function [Kux,Kuy,Kvx,Kvy]=diffrotated(kLarge,kSmall,fldRef);
%
%object: compute slanted diffusive operator coefficients
%
%input:	dxLarge,dySmall	 smoothing scale in direction of 
%                        weak,strong fldRef gradient
%       fldRef           tracer field which gradient defines 
%                        directions of strong,weak smoothing
%output:Kux,Kuy,Kvx,Kvy  slanted diffusion operator coefficients
%
%asumption: dxLarge/dxSmall are given at tracer points (not U/V points)


gcmfaces_global;

%compute the direction of main axis:
%===================================

%1) gradient at cell center
[dTdxAtT,dTdyAtT]=calc_T_grad(fldRef,1);
[dTdxAtT,dTdyAtT]=exch_UV_N(dTdxAtT,dTdyAtT);
%2) diffusion coefficients at cell center
kLargeAtT=exch_T_N(kLarge); kSmallAtT=exch_T_N(kSmall);
%3) interpolate to U/V points
dTdxAtU=gcmfaces; dTdxAtV=gcmfaces;
dTdyAtU=gcmfaces; dTdyAtV=gcmfaces;
kLargeAtU=gcmfaces; kLargeAtV=gcmfaces;
kSmallAtU=gcmfaces; kSmallAtV=gcmfaces;
for iF=1:mygrid.nFaces;

    dTdxAtU{iF}=0.5*(dTdxAtT{iF}(1:end-2,2:end-1)+dTdxAtT{iF}(2:end-1,2:end-1));
    dTdyAtU{iF}=0.5*(dTdyAtT{iF}(1:end-2,2:end-1)+dTdyAtT{iF}(2:end-1,2:end-1));
    kLargeAtU{iF}=0.5*(kLargeAtT{iF}(1:end-2,2:end-1)+kLargeAtT{iF}(2:end-1,2:end-1));
    kSmallAtU{iF}=0.5*(kSmallAtT{iF}(1:end-2,2:end-1)+kSmallAtT{iF}(2:end-1,2:end-1));

    dTdxAtV{iF}=0.5*(dTdxAtT{iF}(2:end-1,1:end-2)+dTdxAtT{iF}(2:end-1,2:end-1));
    dTdyAtV{iF}=0.5*(dTdyAtT{iF}(2:end-1,1:end-2)+dTdyAtT{iF}(2:end-1,2:end-1));
    kLargeAtV{iF}=0.5*(kLargeAtT{iF}(2:end-1,1:end-2)+kLargeAtT{iF}(2:end-1,2:end-1));
    kSmallAtV{iF}=0.5*(kSmallAtT{iF}(2:end-1,1:end-2)+kSmallAtT{iF}(2:end-1,2:end-1));

end;


%compute diffusion operator : (rotated to the direction of main axis)
%===========================

%at U points
dFLDn=sqrt(dTdxAtU.^2+dTdyAtU.^2);
cs=dTdyAtU; sn=-dTdxAtU;
cs(dFLDn>0)=cs(dFLDn>0)./dFLDn(dFLDn>0); 
sn(dFLDn>0)=sn(dFLDn>0)./dFLDn(dFLDn>0);
if 1;
   FLDangleU=gcmfaces;
   for iF=1:mygrid.nFaces; FLDangleU{iF}=atan2(sn{iF},cs{iF}); end;
end;
Kux=cs.*cs.*kLargeAtU+sn.*sn.*kSmallAtU;
Kuy=cs.*sn.*(-kLargeAtU+kSmallAtU);
%at V points
dFLDn=sqrt(dTdxAtV.^2+dTdyAtV.^2);
cs=dTdyAtV; sn=-dTdxAtV;
cs(dFLDn>0)=cs(dFLDn>0)./dFLDn(dFLDn>0); 
sn(dFLDn>0)=sn(dFLDn>0)./dFLDn(dFLDn>0);
if 1;
   FLDangleV=fldRef;
   for iF=1:mygrid.nFaces; FLDangleV{iF}=atan2(sn{iF},cs{iF}); end;
end;
Kvy=sn.*sn.*kLargeAtV+cs.*cs.*kSmallAtV;
Kvx=cs.*sn.*(-kLargeAtV+kSmallAtV);

