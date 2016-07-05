function r = not(p)
%overloaded gcmfaces not function :
%  simply calls double not function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=~p.f' iF ';']); 
end;


