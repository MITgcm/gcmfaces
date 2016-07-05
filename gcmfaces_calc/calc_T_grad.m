function [varargout]=calc_T_grad(fld,putGradOnTpoints);
%object:    compute horizontal gradients
%inputs:    fld is the 'tracer' field of interest
%           putGradOnTpoints states wherther to return the gradients
%               at velocity points (0) or on tracer points (1)
%output:    [dFLDdx,dFLDdy] are the gradient fields
%optional:  [...,dFLDdxdx,dFLDdydy] are the second order 
%               derivatives at tracer points.

global mygrid;

msk=fld; msk(~isnan(fld))=1;

FLD=exch_T_N(fld);
dFLDdx=fld; dFLDdy=fld;
for iF=1:FLD.nFaces;
   tmpA=FLD{iF}(2:end-1,2:end-1);
   tmpB=FLD{iF}(1:end-2,2:end-1);
   dFLDdx{iF}=(tmpA-tmpB)./mygrid.DXC{iF};
   tmpA=FLD{iF}(2:end-1,2:end-1);
   tmpB=FLD{iF}(2:end-1,1:end-2);
   dFLDdy{iF}=(tmpA-tmpB)./mygrid.DYC{iF};
end;

if nargout>2; %compute second order derivatives
   [DX,DY]=exch_UV(dFLDdx,dFLDdy);
   dFLDdxdx=fld; dFLDdydy=fld; dFLDdxdy=fld; dFLDdydx=fld;
   for iF=1:FLD.nFaces;
      tmpA=DX{iF}(2:end,:);
      tmpB=DX{iF}(1:end-1,:);
      dFLDdxdx{iF}=(tmpA-tmpB)./mygrid.DXF{iF};
      tmpA=DY{iF}(:,2:end);
      tmpB=DY{iF}(:,1:end-1);
      dFLDdydy{iF}=(tmpA-tmpB)./mygrid.DYF{iF};
   end;
end;

if putGradOnTpoints;
   dFLDdx(isnan(dFLDdx))=0; dFLDdy(isnan(dFLDdy))=0;
   dFLDdx0=dFLDdx; dFLDdy0=dFLDdy;
   [dFLDdx,dFLDdy]=exch_UV(dFLDdx,dFLDdy);
   for iF=1:FLD.nFaces;
      dFLDdx{iF}=0.5*(dFLDdx{iF}(1:end-1,:)+dFLDdx{iF}(2:end,:));
      dFLDdy{iF}=0.5*(dFLDdy{iF}(:,1:end-1)+dFLDdy{iF}(:,2:end));
   end;
   dFLDdx=dFLDdx.*msk; dFLDdy=dFLDdy.*msk;
%remakr: dFLDdxdx and dFLDdydy are on T points already
end;

varargout{1}=dFLDdx;
varargout{2}=dFLDdy;
if nargout>2;
   varargout{3}=dFLDdxdx;
   varargout{4}=dFLDdydy;
end;

