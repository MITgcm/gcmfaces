function [varargout]=gcmfaces_loc_tile(ni,nj,varargin);
%object : compute map of tile indices and (optional) associate
%         select location (1D vectors) with tile indices etc.
%input :  ni,nj is the MITgcm tile size (2 numbers total)
%         (optional)
%  AND    XC,YC (vectors)
%  OR     iTile, jTile, tileNo (vectors)
%  OR     iTile, jTile, XC11, YC11, XCNINJ, YCNINJ (vectors)
%where :
%         XC, YC are lon/lat of the grid point
%         tileNo is the grid point s tile number (assuming no blank tiles)
%         iTile, jTile is the grid point tile index
%         XC11, YC11 is lat/lon for the tile SE corner
%         XCNINJ, YCNINJ is lat/lon for the tile NW corner
%
%output : (nargin==2) tileNo is the map of tile numbers
%         (nargin >3) loc_tile incl. XC,YC, tileNo, XC11, YC11, XCNINJ, YCNINJ
%
%notes : - if XC, YC are provided as input, then loc_tile.XC, YC is nearest neighbor
%        - by assumption tile numbers increase from w to e (2nd dim), 
%           then from s to n (1st dim), then with face number 

gcmfaces_global;
global mytiles;
loc_arrays={'XC','YC','XC11','YC11','XCNINJ','YCNINJ','iTile','jTile','tileNo'};

%1) check that tile arrays are up to date
if isempty(mytiles); 
  mytiles.dirGrid=mygrid.dirGrid; mytiles.nFaces=mygrid.nFaces;
  mytiles.fileFormat=mygrid.fileFormat; mytiles.ioSize=mygrid.ioSize;
  mytiles.ni=-1; mytiles.nj=-1;
end;

test1=strcmp(mytiles.dirGrid,mygrid.dirGrid)&(mytiles.nFaces==mygrid.nFaces)&...
      strcmp(mytiles.fileFormat,mygrid.fileFormat)&(sum(mytiles.ioSize~=mygrid.ioSize)==0);
test2=(mytiles.ni==ni)&(mytiles.nj==nj);

%2) update tile arrays if not up to date
if ~test1|~test2;
  %
  mytiles.dirGrid=mygrid.dirGrid; mytiles.nFaces=mygrid.nFaces;
  mytiles.fileFormat=mygrid.fileFormat; mytiles.ioSize=mygrid.ioSize;
  %
  XC=mygrid.XC; YC=mygrid.YC;
  XC11=XC; YC11=XC; XCNINJ=XC; YCNINJ=XC; iTile=XC; jTile=XC; tileNo=XC;
  tileCount=0;
  for iF=1:XC11.nFaces;
    face_XC=XC{iF}; face_YC=YC{iF};
    for ii=1:size(face_XC,1)/ni;
        for jj=1:size(face_XC,2)/nj;
%the MITgcm exch2 package proceeds this way instead:
%     for jj=1:size(face_XC,2)/nj;
%         for ii=1:size(face_XC,1)/ni;            
            tileCount=tileCount+1;
            tmp_i=[1:ni]+ni*(ii-1);
            tmp_j=[1:nj]+nj*(jj-1);
            tmp_XC=face_XC(tmp_i,tmp_j);
            tmp_YC=face_YC(tmp_i,tmp_j);
            XC11{iF}(tmp_i,tmp_j)=tmp_XC(1,1);
            YC11{iF}(tmp_i,tmp_j)=tmp_YC(1,1);
            XCNINJ{iF}(tmp_i,tmp_j)=tmp_XC(end,end);
            YCNINJ{iF}(tmp_i,tmp_j)=tmp_YC(end,end);
            iTile{iF}(tmp_i,tmp_j)=[1:ni]'*ones(1,nj);
            jTile{iF}(tmp_i,tmp_j)=ones(ni,1)*[1:nj];
            tileNo{iF}(tmp_i,tmp_j)=tileCount*ones(ni,nj);
        end;
    end;
  end;

  for iF=1:length(loc_arrays);
    eval(['mytiles.' loc_arrays{iF} '=convert2array(' loc_arrays{iF} ');']);
    eval(['clear ' loc_arrays{iF} ';']);
  end;
end;

%3) decide what is needed based on the number or arguments
%   (this needs to happen after mytiles is computed, since 
%    I use the same variable names in that bloc and below) 
if nargin==2;
  %simply return mytiles as loc_tile
  tileNo=convert2array(mytiles.tileNo);
  varargout={tileNo};
  return;
elseif nargin==4;
  XC=varargin{1}; YC=varargin{2}; 
  tmp1=find(XC>180); XC(tmp1)=XC(tmp1)-360;
  iTile=[]; jTile=[]; tileNo=[];
  XC11=[]; YC11=[]; XCNINJ=[]; YCNINJ=[];
elseif nargin==5;
  XC=[]; YC=[];
  iTile=varargin{1}; jTile=varargin{2}; tileNo=varargin{3};
  XC11=[]; YC11=[]; XCNINJ=[]; YCNINJ=[];
elseif nargin==8;
  XC=[]; YC=[];
  iTile=varargin{1}; jTile=varargin{2}; tileNo=[];
  XC11=varargin{3}; YC11=varargin{4}; XCNINJ=varargin{5}; YCNINJ=varargin{6};
else;
  error('wrong argument list');
end;

%3) find the grid points indices in array format
if ~isempty(XC);
  %identify nearest neighbor on the sphere
  XCgrid=convert2array(mygrid.XC);
  YCgrid=convert2array(mygrid.YC);
  x=sin(pi/2-YCgrid*pi/180).*cos(XCgrid*pi/180);
  y=sin(pi/2-YCgrid*pi/180).*sin(XCgrid*pi/180);
  z=cos(pi/2-YCgrid*pi/180);
  xx=sin(pi/2-YC*pi/180).*cos(XC*pi/180);
  yy=sin(pi/2-YC*pi/180).*sin(XC*pi/180);
  zz=cos(pi/2-YC*pi/180);
  kk=find(~isnan(x));
  if size(xx,1)==1; xx=xx'; yy=yy'; zz=zz'; end;
  if ~isempty(which('knnsearch'));
      ik = knnsearch([x(kk) y(kk) z(kk)],[xx yy zz]);
  else;
      %this would correspond to the old bindata method: 
      % X=[XCgrid(kk) YCgrid(kk)]; Y=[XC YC];
      %this corresponds to the knnsearch method:
      X=[x(kk) y(kk) z(kk)]; Y=[xx yy zz];
      TRI=delaunayn(X); ik=dsearchn(X,TRI,Y);
  end;
  ik=kk(ik);
  %
  %(old method that uses longitude, latitude directly)
  %tmp1=find(XC>180); XC(tmp1)=XC(tmp1)-360;
  %ik=gcmfaces_bindata(XC,YC);
else;
  %use mytiles as a look up table
  ik=zeros(size(iTile));
  for ikk=1:length(iTile);
    if ~isempty(tileNo);
      tmp1=find(mytiles.iTile==iTile(ikk)&mytiles.jTile==jTile(ikk)&mytiles.tileNo==tileNo(ikk));
    else;
      tmp1=find(mytiles.iTile==iTile(ikk)&mytiles.jTile==jTile(ikk)&...
                abs(mytiles.XC-XC(ikk))<1e-4&...
                abs(mytiles.YC-YC(ikk))<1e-4&...
                abs(mytiles.XC11-XC11(ikk))<1e-4&...  
                abs(mytiles.YC11-YC11(ikk))<1e-4&...    
                abs(mytiles.XCNINJ-XCNINJ(ikk))<1e-4&...
                abs(mytiles.YCNINJ-YCNINJ(ikk))<1e-4);
    end;
    if isempty(tmp1); error('grid point could not be identified from inputs'); end;
    ik(ikk)=tmp1(1);
  end;
end;

loc_tile.point=ik;

%4) complement location arrays and prepare output
for iF=1:length(loc_arrays);
  eval(['loc_tile.' loc_arrays{iF} '=mytiles.' loc_arrays{iF} '(ik);']);
end;

%5) output result
varargout={loc_tile};



