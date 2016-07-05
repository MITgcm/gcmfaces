function r = power(p,q)
%overloaded gcmfaces power function :
%  simply calls double power function for each face data
%  if any of the two arguments is a gcmfaces object

if isa(p,'gcmfaces'); r=p; else; r=q; end; 
for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   if isa(p,'gcmfaces')&isa(q,'gcmfaces'); 
       eval(['r.f' iF '=p.f' iF '.^q.f' iF ';']); 
   elseif isa(p,'gcmfaces')&isa(q,'double');
       eval(['r.f' iF '=p.f' iF '.^q;']);
   elseif isa(p,'double')&isa(q,'gcmfaces');
       eval(['r.f' iF '=p.^q.f' iF ';']);
   else;
      error('gcmfaces power: types are incompatible')
   end;
end;


