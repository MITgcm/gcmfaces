function []=write2file(fileOut,fldIn,varargin);
%purpose:       write array to binary file
%
%inputs:        fileOut is the file name
%		fldIn is the array to write to disk
%(optional)	prec is the file precision (32, by default, or 64)

if nargin>2; prec=varargin{1}; else; prec=32; end;
if nargin>3; omitNaNs=varargin{2}; else; omitNaNs=1; end;
    
if ~ischar(fldIn);
    fid=fopen(fileOut,'w','b'); tmp1=fldIn; 
    if omitNaNs; tmp1(isnan(tmp1))=0; end;
    fwrite(fid,tmp1,['float' num2str(prec)]);
    fclose(fid);
else;
    fid=fopen(fileOut,'wt'); fwrite(fid,fldIn); fclose(fid);
end;



