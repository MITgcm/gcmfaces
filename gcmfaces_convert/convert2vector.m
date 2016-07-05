function [a]=convert2vector(b,method);
%[a]=CONVERT2VECTOR(b,method); 
%   converts gcmfaces object b to vector format a -- and vice versa 
%   when b is instead a vector obtained ealier using convert2vector.
%
%   With the 'new' method (default): each 2D field becomes a column vector, 
%   while the other dimensions remain the same; convert2gcmfaces is used.
%   With the 'old' method : convert2array is used and the third+
%   dimensions of b get conflated in the column vector length.
%
%   The 'old' method will get removed after updating routines that use convert2vector.

global mygrid;

if isa(b,'gcmfaces'); do_gcmfaces2vector=1; else; do_gcmfaces2vector=0; end;
if isempty(whos('method')); method='new'; end;

if strcmp(method,'new');
if do_gcmfaces2vector;
  bb=convert2gcmfaces(b);
  siz=size(bb); if length(siz)==2; siz=[siz 1]; end;
  a=reshape(bb,[prod(siz(1:2)) siz(3:end)]);
else;
  bb=convert2gcmfaces(mygrid.XC);
  siz=size(b);
  bb=reshape(b,[size(bb) siz(2:end)]);
  a=convert2gcmfaces(bb);
end;
end;

if strcmp(method,'old');
if do_gcmfaces2vector;
  bb=convert2array(b);
  a=bb(:);
else;
  bb=convert2array(mygrid.XC);
  if mod(length(b(:)),length(bb(:)))~=0;
      error('vector length is inconsistent with gcmfaces objects');
  else;
      n3=length(b(:))/length(bb(:));
  end;
  b=reshape(b,[size(bb) n3]);
  a=convert2array(b);
end;
end;



