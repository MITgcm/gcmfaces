function [VARvalue]=ncgetvar(nc,VARname,varargin)
% function [VARvalue]=ncgetvar(nc,VARname, [index_prof, index_depth] )
%   get data to MITprof netcdf file

global useNativeMatlabNetcdf; 
if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;

if useNativeMatlabNetcdf
    
    %get variable id:
    vv = netcdf.inqVarID(nc,VARname);
    if nargin>2;
        %get and flip position vectors:
        VARpos=fliplr(varargin);
        %convert VARpos to start,count:
        start=[]; count=[];
        for ii=1:length(VARpos);
            start=[start VARpos{ii}(1)-1];
            count=[count VARpos{ii}(end)-VARpos{ii}(1)+1];
        end;
        %write to file:
        VARvalue=netcdf.getVar(nc,vv,start,count);
    else;
        %write to file:
        VARvalue=netcdf.getVar(nc,vv);
    end;
    %flip order of dimensions:
    bb=length(size(VARvalue)); VARvalue=permute(VARvalue,[bb:-1:1]);
    
    
else;%try to use old mex stuff
    
    if nargin==3;
        eval(['VARvalue=nc{''' VARname '''}([' num2str(varargin{1}) ']);']);
    elseif nargin==4,
        eval(['VARvalue=nc{''' VARname '''}([' num2str(varargin{1}) '],[' num2str(varargin{2}) ']);']);
    else;
        eval(['VARvalue=nc{''' VARname '''}(:);']);
    end;
    
end;
