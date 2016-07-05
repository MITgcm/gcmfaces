function [varargout]=calc_boxmean_T(fld,varargin);
%purpose: compute a weighted average of a field
%
%inputs:
%	(1) fld is a 3D (or 2D) field in gcmfaces format at the grid 
%		center where missing values are assigned a NaN	
%	(2a) 'LATS',LATS is a line vector of latitutde interval edges
%	(2b) 'LONS',LONS is a line vector of longitutde interval edges
%	(3a) 'weights',weights is a weights field. If it is not specified
%		then we use the grid cell volume in the weighted average.
%               If specifying 'weights' you likely want to set it to 0 on land.
%	(3b) 'level',kk is a specification of the vertical level. This
%		is only used when fld is a 2D field to define weights
%outputs:
%	(1) FLD is the field/vector/value of the weighted mean. It's 
%		size depends on the input size
%	(2) FLD,X,Y,Z -- FLD is the weighted mean, X,Y,Z are locations
%               that can serve for displaying the result.
%       (3) FLD,W -- FLD is the weighted mean, W are weights computed 
%               for each element of FLD. W can be used to simply compute 
%               the global weighted average as nansum(W(:).*FLD(:))/nansum(W(:))
%       (4) FLD,X,Y,Z,W
%usage:	
%	input 2a and/or 2b is necessary
%       input 3a and 3b are optional and mutually exclusive
%          if neither is specified, then it is assumed that fld
%          is a 3D field (or a series of them) and weight are
%	   the usual grid cell volumes
%	output 2,3,4,5 are optional and allocated depending on call
%       by assumption, mygrid has already been loaded to memory

gcmfaces_global;

%get arguments
for ii=1:(nargin-1)/2;
	tmp1=varargin{2*ii-1}; eval([tmp1 '=varargin{2*ii};']);
end;

%initialize output:
[n1,n2,n3,n4]=size(fld.f1);

%test inputs/outputs consistency:
tmp1=isempty(whos('LONS'))&isempty(whos('LATS'));
if tmp1;
  error('wrong input specification : specify LONS and/or LATS');
end;
tmp1=~isempty(whos('weights'))+~isempty(whos('level'));
if tmp1>1;
  error('wrong input specification : omit weights or level');
end;
if n3~=length(mygrid.RC)&isempty(whos('level'))&isempty(whos('weights'));
  error('wrong input specification : specify weights or level');
end;

%prepare output etc.:
if ~isempty(whos('LONS'))&~isempty(whos('LATS')); %use complex
  valranges=LONS'*ones(size(LATS))+i*(ones(size(LONS))'*LATS); 
  X=0.5*(LONS(1:end-1)+LONS(2:end))';
  Y=0.5*(LATS(1:end-1)+LATS(2:end));
elseif ~isempty(whos('LONS'));
  valranges=LONS'; 
  X=0.5*(LONS(1:end-1)+LONS(2:end))';
  Y=NaN;
else;
  valranges=i*LATS;
  X=NaN;
  Y=0.5*(LATS(1:end-1)+LATS(2:end));
end;
nnranges=size(valranges);
nnout=max(size(valranges)-1,[1 1]);
%
FLD=NaN*ones([nnout n3 n4]);
W=NaN*ones([nnout n3 n4]);
X=repmat(X*ones(1,size(Y,2)),[1 1 n3 n4]);
Y=repmat(ones(size(X,1),1)*Y,[1 1 n3 n4]);

%and corresponding vertical positions:
Z=NaN; if n3>1; Z=[]; Z(1,1,:)=[1:n3]; end;
if isempty(whos('weights'))&isempty(whos('level'));
  Z(1,1,:)=mygrid.RC;
elseif ~isempty(whos('level'));
  Z(1,1,:)=mygrid.RC(level);
end;
[t1,t2,t3,t4]=size(X);
Z=repmat(Z,[t1 t2 1 t4]);

%select weights for average:
if isempty(whos('weights'))&isempty(whos('level'));
  weights=mygrid.hFacC.*mk3D(mygrid.RAC,mygrid.hFacC);
  weights=weights.*mk3D(mygrid.DRF,mygrid.hFacC);
elseif ~isempty(whos('level'));
  weights=mygrid.hFacC(:,:,level).*mygrid.RAC*mygrid.DRF(level);
end;

%check for potential inconsistencies in specified weights :
[w1,w2,w3,w4]=size(weights.f1);
if w3==1&n3>1; weights=repmat(weights,[1 1 n3 n4]); end;
if w4==1&n4>1; weights=repmat(weights,[1 1 1 n4]); end;
test1=sum(weights>0&isnan(fld));
if test1>0; error('non-zero weights found for NaN point'); end;

%switch to 2D array to speed up computation:
fld=convert2array(fld);
n1=size(fld,1); n2=size(fld,2);
fld=reshape(fld,n1*n2,n3*n4);
%same for the weights:
weights=convert2array(weights);
weights=reshape(weights,n1*n2,n3*n4);
%multiply one with the other
fld=fld.*weights;
%remove data mask
fld(isnan(fld))=0;

lonvec=reshape(convert2array(mygrid.XC),n1*n2,1);
latvec=reshape(convert2array(mygrid.YC),n1*n2,1);

for ix=1:nnout(1);
for iy=1:nnout(2);

   %get list ofpoints that form a zonal band:
   if ~isempty(whos('LONS'))&~isempty(whos('LATS'));
     mm=find(latvec>=imag(valranges(ix,iy))&latvec<imag(valranges(ix,iy+1))...
            &lonvec>=real(valranges(ix,iy))&lonvec<real(valranges(ix+1,iy)));
   elseif ~isempty(whos('LATS'));
     mm=find(latvec>=imag(valranges(ix,iy))&latvec<imag(valranges(ix,iy+1)));
   else;
     mm=find(lonvec>=real(valranges(ix,iy))&lonvec<real(valranges(ix+1,iy)));
   end;

   %do the area weighed average along this band: 
   tmp1=nansum(fld(mm,:),1); 
   tmp2=nansum(weights(mm,:),1); 
   tmp2(tmp2==0)=NaN;
   tmp1=tmp1./tmp2;

   %store:
   FLD(ix,iy,:,:)=reshape(tmp1,n3,n4);
   W(ix,iy,:,:)=reshape(tmp2,n3,n4);

end; 
end;

%remove singleton dimensions:
X=squeeze(X); Y=squeeze(Y); Z=squeeze(Z); 
W=squeeze(W); FLD=squeeze(FLD);

%prepare outout:
if nargout==5;
  varargout={FLD,X,Y,Z,W};
elseif nargout==4;
  varargout={FLD,X,Y,Z};
elseif nargout==2;
  varargout={FLD,W};
elseif nargout==1;
  varargout={FLD};
else;
  varargout={};
end;



