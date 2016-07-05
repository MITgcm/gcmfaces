function [] = ncload(fileIn, varargin);

% ncload -- Load NetCDF variables.
%  ncload('fileIn', 'var1', 'var2', ...) loads the
%   given variables of 'fileIn' into the Matlab
%   workspace of the "caller" of this routine.  If no names
%   are given, all variables are loaded.

global useNativeMatlabNetcdf; 
if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;

f = ncopen(fileIn, 'nowrite');
if isempty(f), return, end
vars=ncvars(f);
if isempty(varargin); varargin = vars; end;

if (useNativeMatlabNetcdf);
    
    for i = 1:length(varargin)
        if sum(strcmp(vars,varargin{i}))>0;
            %get variable
            varid = netcdf.inqVarID(f,varargin{i});
            aa=netcdf.getVar(f,varid);
            %inverse the order of dimensions
            bb=length(size(aa)); aa=permute(aa,[bb:-1:1]);
            %replace missing value with NaN
            [atts]=ncatts(f,varid);
            if strcmp(atts,'missing_value')&isreal(aa);
                spval = double(netcdf.getAtt(f,varid,'missing_value'));
            elseif strcmp(atts,'_FillValue')&isreal(aa);
                spval = double(netcdf.getAtt(f,varid,'_FillValue'));
            else;
                spval=[];
            end;
            if ~isempty(spval); aa(aa==spval)=NaN; end;
        else;
            aa=[];
        end;
        assignin('caller', varargin{i}, aa)
    end
    
    
    
    
else;%try to use old mex stuff
    
    
    for i = 1:length(varargin)
        if ~isstr(varargin{i}), varargin{i} = inputname(i+1); end
        oldfld = f{varargin{i}}(:);
        spval = f{varargin{i}}.missing_value(:);
        if isempty(spval);
            spval = f{varargin{i}}.FillValue_(:);
        end
        fld = oldfld;
        if ~isempty(spval)&~ischar(fld);
            replace = find(oldfld == spval);
            nreplace = length(replace);
            if nreplace>0
                fld(replace) = NaN*ones(1,nreplace);
            end %if
        end %if
        %NaN-substitution messes up backward compatibility so I comment it out
        %        assignin('caller', varargin{i}, fld);
        %and revert to oldfld
        assignin('caller', varargin{i}, oldfld)
    end
    
end

ncclose(f);

