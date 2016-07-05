function [varargout]=depthStretchPlot(plotName,plotData,varargin);
%object:    front end to plot/pcolor/etc. using a stretched depth coordinate (see depthStretch.m)
%inputs:    plotName is the name of the plotting routine (e.g. 'pcolor')
%           plotData is the list or arguments to pass over to the plotting routine
%               in a cell array (e.g. {depth,time,temperature}), with the
%               depth coordinate coming second (as usual for plot/pcolor/etc.)
%optional:  depthTics is the vector of yTics depths
%           depthStretchLim are the stretching depth limits ([0 500 6000] by default)
%               to pass over to depthStretch (type 'help depthStretch' for details).
%
%notes:     the depth coordinate must be first in plotData

%get depthStretchDef if provided
if nargin>2; depthTics=varargin{1}; else; depthTics=[0:100:500 750 1000:500:6000]; end;
if nargin>3; depthStretchDef=varargin{2}; else; depthStretchDef=[0 500 6000]; end;

%replace it with stretched coordinate:
plotData{2}=depthStretch(abs(plotData{2}),depthStretchDef);

%do the very plot:
eval(['h=' plotName '(plotData{:});']);

%take care of depth tics in stretched coordinate:
depthTics=sort(depthTics,'descend');

depthTicsLabel=[];
for kkk=1:length(depthTics)
depthTicsLabel=strvcat(depthTicsLabel,num2str(depthTics(kkk)));
end

depthTics=depthStretch(depthTics,depthStretchDef);
set(gca,'YTick',depthTics);
set(gca,'YTickLabel',depthTicsLabel);

%output plot handle:
if nargout>0; varargout={h}; end;




