function r = prctile(p,varargin)
%overloaded gcmfaces prctile function (operates on full domain)

tmp1=convert2gcmfaces(p);
r=prctile(tmp1(:),varargin{1});

