function []=grid_add_time(timeVec,timeUnits)
% grid_add_time(timeVec,timeUnits) adds a time axis to mygrid for use e.g. 
% when writing netcdf files via prep2nctiles.m
%   Inputs:
%       timeVec: a vector containing the times associated with model output. 
%                Must be same length as the number of output files / records.
%       timeUnits: units for the time axis (ex: 'days since 1992-1-1 0:0:0')
%   Usage:
%       addTime([14 45 74],'days since 1992-1-1 0:0:0') % 3 records at 14,
%       45 and 74 days since 01/01/1992.

% Bring mygrid to function scope
gcmfaces_global;

% Add time info to mygrid
mygrid.timeVec = timeVec;
mygrid.timeUnits = timeUnits;

end

