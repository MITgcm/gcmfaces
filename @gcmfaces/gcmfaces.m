function s=gcmfaces(varargin);
%object:    create an empty gcmfaces object
%input:     fld cell array containing each face data
%      OR   nFaces number of faces (empty faces in output)
%      OR   (none; results in empty face data, with nFaces=mygrid.nFaces)
%output:    gcmfaces object


%object:    create an empty gcmfaces object
%input:     fld cell array containing each face data
%      OR   nFaces,fld          (to add consistency check)
%      OR   nFaces number of faces (empty faces in output)
%      OR   (none)                 (empty faces in output)
%output:    gcmfaces object formatted/filled accordingly


global mygrid;

if nargin==2;
    nFaces=varargin{1};
    fld=varargin{2};
    if ~iscell(fld)|length(fld)~=nFaces;
        error('inconsistent spec. of nFaces,fld');
    end;
elseif nargin==1;
    tmp1=varargin{1};
    if iscell(tmp1);
        fld=tmp1;
        nFaces=length(fld);
    else;
        nFaces=varargin{1};
        fld=[];
    end;
elseif isfield(mygrid,'nFaces');
    nFaces=mygrid.nFaces;
    fld=[];
else;
    nFaces=1;
    fld=[];
    warning('nFaces set to 1 by default');
end;

if nFaces==1; gridType='ll';
elseif nFaces==4; gridType='llpc';
elseif nFaces==5; gridType='llc';
elseif nFaces==6; gridType='cube';
else; error('wrong gcmfaces definition');
end;

nFacesMax=6;

if iscell(fld);
    s.nFaces=length(fld);
    s.gridType=gridType;
    for iF=1:s.nFaces;
        eval(['s.f' num2str(iF) '=fld{iF};']);
    end;
    for iF=s.nFaces+1:nFacesMax;
        eval(['s.f' num2str(iF) '=[];']);
    end;
else;
    s.nFaces=nFaces;
    s.gridType=gridType;
    for iF=1:nFacesMax;
        eval(['s.f' num2str(iF) '=[];']);
    end;
end;

s = class(s,'gcmfaces');

