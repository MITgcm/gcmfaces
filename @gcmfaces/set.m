function a = set(a,varargin)
%overloaded gcmfaces set function :
%   V = SET(H,'PropertyName',PropertyValue) sets the value of the specified
%   attribute (e.g. nFaces and gridType) of a gcmfaces object H.

propertyArgIn = varargin;
while length(propertyArgIn) >= 2,
   propName = propertyArgIn{1};
   val = propertyArgIn{2};
   propertyArgIn = propertyArgIn(3:end);
   eval(['a.' propName '=val;']);
end

