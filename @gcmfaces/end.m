function ind = end(self,k,n);
%overloaded gcmfaces end function :
%  simply calls double end function for face #1 if the first argument is a gcmfaces object
%  Note: is only valid for dimensions>=3

if k<3; error('@gcmfaces/end.m is only valid for dimensions>=3'); end;

%not sure why but the following leads to perpetual loop in octave: 
%ind = builtin('end', self.f1, k, n);
f1=getfield(struct(self),'f1'); 
ind=size(f1,k);

