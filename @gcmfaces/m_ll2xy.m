function [xx,yy] = m_ll2xy(x,y,varargin)
%overloaded gcmfaces m_ll2xy function :
%  simply calls m_map's m_ll2xy function for each face data
%  if the first two arguments (lon and lat) are gcmfaces objects
%  passing over the other arguments

xx=x; yy=y;

for iFace=1:x.nFaces;
   iF=num2str(iFace); 
   eval(['[tmpx,tmpy]=m_ll2xy(x.f' iF ',y.f' iF ',varargin{:});']);
   eval(['xx.f' iF '=tmpx; yy.f' iF '=tmpy;']); 
end;


