function val = get(a, propName)
%overloaded gcmfaces get function :
%   V = GET(H,'PropertyName') returns the value of the specified
%   attribute (e.g. nFaces and gridType) of a gcmfaces object H.

eval(['val = a.' propName ';']);

