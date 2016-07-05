function [fldOut]=read2memory(fileIn,varargin);
%purpose:	load binary file to memory
%
%inputs:	fileIn is the file name
%(optional)	sizeOut is the output array size (or [] if not known)
%		prec is the file precision (32, by default, or 64)
%
%output:	fldOut is the binary vector (default) or array (if sizeOut is spec.)

if nargin>1; sizeOut=varargin{1}; else; sizeOut=[]; end;
if nargin>2; prec=varargin{2}; else; prec=32; end;

if ~strcmp(fileIn(end-2:end),'txt');
    nn=dir(fileIn); nn=nn.bytes/(prec/8); fid=fopen(fileIn,'r','b'); fldOut=fread(fid,nn,['float' num2str(prec)]); fclose(fid);
else;
    error('text read is not implemented\n');
    %     fid=fopen(fileIn,'rt'); fread(fid,fldOut); fclose(fid);
end;

if ~isempty(sizeOut); fldOut=reshape(fldOut,sizeOut); end; 




