function ind = end(self,k,n);
%overloaded gcmfaces end function :
%  simply calls double end function for face #1 if the first argument is a gcmfaces object
%  Note: is only valid for dimensions>=3

if k<3; error('@gcmfaces/end.m is only valid for dimensions>=3'); end;
ind = builtin('end', self.f1, k, n);

