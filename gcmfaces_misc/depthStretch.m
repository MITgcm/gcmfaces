function [z]=depthStretch(d,varargin)
%object:    compute stretched depth coordinate
%inputs:    d is the depth vector (>=0)
%optional:  depthStretchLim are the stretching depth limits ([0 500 6000] by default)
%
%this routine maps
%[depthStretchLim(1) depthStretchLim(2)] 	to [1 0]
%[depthStretchLim(2) depthStretchLim(3)] 	to [0 -1]

if nargin>1; depthStretchLim=varargin{1}; else; depthStretchLim=[0 500 6000]; end;

zStretchLim=[1 0 -1];

%make sure depth is positive
d=abs(d);

%initialize stretched vertical coordinate
z=zeros(size(d));

%values between 0 and depthStretchLim(2) get half the range of z
tmp1=find(d<=depthStretchLim(2));
tmp2=(depthStretchLim(2)-d(tmp1))./(depthStretchLim(2)-depthStretchLim(1))...
    .*(zStretchLim(1)-zStretchLim(2))+zStretchLim(2);
z(tmp1)=tmp2;

%values between depthStretchLim(2) and depthStretchLim(3) get the other half z range
tmp1=find(d>depthStretchLim(2));
tmp2=(d(tmp1)-depthStretchLim(2))./(depthStretchLim(3)-depthStretchLim(2))...
    .*(zStretchLim(3)-zStretchLim(2))+zStretchLim(2);
z(tmp1)=tmp2;



