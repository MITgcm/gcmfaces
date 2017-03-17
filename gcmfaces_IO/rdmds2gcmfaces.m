function [fldOut,IT,M]=rdmds2gcmfaces(varargin);
%object:    read with rmds then apply convert2gcmfaces
%input:     varargin are the options to pass to rdmds (type help rdmds)
%output:    fldOut is a gcmfaces object
%
%note:      an earlier version was expecting nFaces to be passed
%           as the last argument; this is not the case anymore.

gcmfaces_global;

[v0,IT,M]=rdmds(varargin{1:end});

nn=size(v0);
test1=isfield(mygrid,'xtrct');
test1=test1&(prod(mygrid.ioSize)~=prod(nn(1:2)));
if test1;
    if length(nn)==2; nn=[nn 1]; end;
    v0=reshape(v0,[nn(1)*nn(2) nn(3:end)]);
    v0=v0(mygrid.xtrct_inFull,:,:,:);
    v0=reshape(v0,[mygrid.ioSize nn(3:end)]);
end;

fldOut=convert2gcmfaces(v0);
