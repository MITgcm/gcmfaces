function [X,Y,FLD]=convert2pcol(varargin);
%object:    gcmfaces to 'pcolor format' conversion
%inputs:    x is longitude (e.g. mygrid.XC)
%           y is latitude (e.g. mygrid.YC)
%           fld is the 2D field of interest (e.g. mygrid.hFacC(:,:,1))
%outputs:   X,Y,FLD are array versions of x,y,fld
%
%note:      this function is designed so that one may readily
%           plot the output in geographic coordinates
%           using e.g. 'figure; pcolor(X,Y,FLD);'

input_list_check('convert2pcol',nargin);

gcmfaces_global;

c=varargin{1};

if isfield(mygrid,'xtrct');
   [X,Y,FLD]=convert2pcol_xtrct(varargin{:});
elseif strcmp(c.gridType,'llc');
   [X,Y,FLD]=convert2pcol_llc(varargin{:});
elseif strcmp(c.gridType,'cube');
   [X,Y,FLD]=convert2pcol_cube(varargin{:});
elseif strcmp(c.gridType,'llpc');
   [X,Y,FLD]=convert2pcol_llpc(varargin{:});
elseif strcmp(c.gridType,'ll');
   [X,Y,FLD]=convert2pcol_ll(varargin{:});
else;
   error(['convert2pcol not implemented for ' c.gridType '!?']);
end;

