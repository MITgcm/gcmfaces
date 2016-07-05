function [FLD]=convert2array_ll(fld);
%object:    gcmfaces to array format conversion (if gcmfaces input)
%    or:    array to gcmfaces format conversion (if array input)
%
%notes:     if array input, the gcmfaces format will be the one of mygrid.XC, so 
%           the array input must have originally been created according to convert2array

global mygrid;

if isa(fld,'gcmfaces'); do_gcmfaces2array=1; else; do_gcmfaces2array=0; end;

if do_gcmfaces2array;
   FLD=fld.f1;
else;
   FLD=NaN*mygrid.XC;
   FLD.f1=fld;
end;


