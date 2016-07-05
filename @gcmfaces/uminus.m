function r = uminus(p)
%overloaded gcmfaces uminus function :
%  simply calls double uminus function for each face data

r=p;
for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=-p.f' iF ';']); 
end;


