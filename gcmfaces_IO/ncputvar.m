function []=ncputvar(nc,VARname,VARvalue,varargin);
% []=ncputvar(ncid,varid,data,[start,count])
%   write data to MITprof netcdf file

global useNativeMatlabNetcdf; if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;

if useNativeMatlabNetcdf
    
    %get variable id:
    vv = netcdf.inqVarID(nc,VARname);
    %flip order of dimensions:
    bb=length(size(VARvalue)); VARvalue=permute(VARvalue,[bb:-1:1]);
    if nargin>3;
        %get and flip position vectors:
        VARpos=fliplr(varargin);
        %convert VARpos to start,count:
        start=[]; count=[];
        for ii=1:length(VARpos);
            start=[start VARpos{ii}(1)-1];
            count=[count VARpos{ii}(end)-VARpos{ii}(1)+1];
        end;
        %write to file:
        netcdf.putVar(nc,vv,start,count,VARvalue);
    else;
        %write to file:
        netcdf.putVar(nc,vv,VARvalue);
    end;

    
else;%try to use old mex stuff
    
    if nargin==4;
        eval(['nc{''' VARname '''}([' num2str(varargin{1}) '])=VARvalue;']);
    elseif nargin==5,
        eval(['nc{''' VARname '''}([' num2str(varargin{1}) '],[' num2str(varargin{2}) '])=VARvalue;']);
    else;
        eval(['nc{''' VARname '''}(:)=VARvalue;']);
    end;
    
end;
