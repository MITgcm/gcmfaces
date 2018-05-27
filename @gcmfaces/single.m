function r = single(p)
%overloaded gcmfaces single function : 
%  simply calls double single function for each face data

r=p;
for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=single(p.f' iF ');']); 
end;


