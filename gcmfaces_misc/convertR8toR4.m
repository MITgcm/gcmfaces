function []=convertR8toR4(fileIn,fileOut);
%object:        read R8 fileIn, write R4 fileOut
%inputs:        fileIn and fileOut

tmp1=dir(fileIn);
tmp1=tmp1.bytes/8;
fid=fopen(fileIn,'r','b'); tmp2=fread(fid,tmp1,'float64'); fclose(fid);
fid=fopen(fileOut,'w','b'); fwrite(fid,tmp2,'float32'); fclose(fid);


