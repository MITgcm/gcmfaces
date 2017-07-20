function [x,y]=m_map_fix_range(x,y);
% [x,y]=M_MAP_FIX_RANGE(x,y) adjust the longitude range depening on MAP_VAR_LIST.ulongs

global MAP_VAR_LIST;

if isfield(MAP_VAR_LIST,'ulongs');
    lmin=MAP_VAR_LIST.ulongs(1);
    lmax=MAP_VAR_LIST.ulongs(2);
    x(find(x>lmax))=x(find(x>lmax))-360;
    x(find(x<lmin))=x(find(x<lmin))+360;
end;
