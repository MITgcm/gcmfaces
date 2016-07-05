function r = uplus(p)
%overloaded gcmfaces uplus function :
%  simply calls double uplus function for each face data

r=p;
for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=+p.f' iF ';']); 
end;


