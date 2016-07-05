function [a]=convert2array(b,varargin);
%object:    gcmfaces to array format conversion (if gcmfaces input)
%    or:    array to gcmfaces format conversion (if array input)
%
%notes:     - if array input, the gcmfaces format will be the one of mygrid.XC, so 
%           the array input must have originally been created according to convert2array
%           - global mygrid parameters (mygrid.XC.gridType) are used

input_list_check('convert2array',nargin);

gcmfaces_global;

if isfield(mygrid,'xtrct');
   a=convert2array_xtrct(b);
elseif strcmp(mygrid.XC.gridType,'llc');
   a=convert2array_llc(b); 
elseif strcmp(mygrid.XC.gridType,'cube');
   a=convert2array_cube(b);
elseif strcmp(mygrid.XC.gridType,'llpc');
   a=convert2array_llpc(b);
elseif strcmp(mygrid.XC.gridType,'ll');
   a=convert2array_ll(b);
else;
   error(['convert2array not implemented for ' mygrid.XC.gridType '!?']);
end;

