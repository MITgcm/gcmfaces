function []=qwckplot(fld);
%does a quick display of a 2D field according
%to imagescnan(convert2array(fld)'); axis xy;

imagescnan(convert2array(fld)'); axis xy;


