function r = double(p)
%overloaded gcmfaces double function : 
%  simply calls double double function for each face data

r=p;
for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=double(p.f' iF ');']); 
end;


