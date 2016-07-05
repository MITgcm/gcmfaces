function []=write2meta(myFile,myDim,varargin);
%purpose:       write meta file to match binary file
%
%inputs:        myFile is the file name (must finish with '.data')
%               myDim is the size of a field (2D or 3D integer vector)
%(optional 1)   myPrec is the file myPrecision (32, by default, or 64)
%(optional 2)   fldList is the list of field names (cell array)

%precision:
if nargin>2; myPrec=varargin{1}; else; myPrec=32; end;
if nargin>3; fldList=varargin{2}; else; fldList=[]; end;
%number of dimensions
nDim=length(myDim);
%number of records:
tmp1=dir(myFile);
nRec=tmp1.bytes/myDim(1)/myDim(2)/myPrec*8;
if nDim>2; nRec=nRec/myDim(3); end;
if nRec<1|floor(nRec)~=nRec; error('inconsistent dimensions'); end;
%check that creating a meta file makes sense w\r\t rdmds
if ~strcmp(myFile(end-4:end),'.data');
  error('file name must finish in ''.data''\n');
else;
  myFile=[myFile(1:end-5) '.meta'];
end;

%create the meta file:
fid=fopen(myFile,'wt'); 
%%
fprintf(fid,'nDims = [   %i ];\n',min(nDim,3));
fprintf(fid,' dimList = [\n');
fprintf(fid,' %5i, %5i, %5i,\n',myDim(1),1,myDim(1));
fprintf(fid,' %5i, %5i, %5i,\n',myDim(2),1,myDim(2));
if nDim>2; fprintf(fid,' %5i, %5i, %5i,\n',myDim(3),1,myDim(3)); end;
fprintf(fid,' ];\n');
fprintf(fid,' dataprec = [ ''float%2i'' ];\n',myPrec);
fprintf(fid,' nrecords = [ %5i ];\n',nRec);
if ~isempty(fldList);
  nFlds=length(fldList);
  fprintf(fid,' nFlds = [   %i ];\n',nFlds);
  fprintf(fid,' fldList = {\n');
  txt=' '; for ii=1:length(fldList); txt=[txt '''' fldList{ii} '''' ' ']; end;
  fprintf(fid,[txt '\n']);
  fprintf(fid,' };\n');
end;
%%
fclose(fid);

