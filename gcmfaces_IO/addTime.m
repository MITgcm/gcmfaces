function addTime(timeVec,units)
%addTime Adds timeseries information to mygrid to use when writing netCDF
%files
%   Inputs:
%       timeVec: a vector containing the timeseries. Must be same length as
%       the number of time steps.
%       units: units for timeseries (ex: 'days since 1992-1-1 0:0:0')
%   Usage:
%       addTime([14 45 74],'days since 1992-1-1 0:0:0') % 3 time steps 14,
%       45 and 74 days since 01/01/1992.

% Get Grid
gcmfaces_global;

% Add time info to grid for writing to NCtiles
mygrid.timeVec = timeVec;
mygrid.timeUnits = units;


end

