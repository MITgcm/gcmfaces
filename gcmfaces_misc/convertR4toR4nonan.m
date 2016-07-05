function []=convertR4toR4nonan(fileIn,fileOut);
%object:	read R4 fileIn, replace NaN with 0, write R4 fileOut
%inputs:	fileIn and fileOut

tmp1=dir(fileIn);
tmp1=tmp1.bytes/4;
fid=fopen(fileIn,'r','b'); tmp2=fread(fid,tmp1,'float32'); fclose(fid);
tmp2(find(isnan(tmp2)))=0;
fid=fopen(fileOut,'w','b'); fwrite(fid,tmp2,'float32'); fclose(fid);


