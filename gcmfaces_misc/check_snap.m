
listBudgs={'budgMo','budgHo','budgSo','budgMi','budgHi','budgSi'};
dt=(0000174564-0000000732)*3600;
for ii=1:length(listBudgs);
  budgName=listBudgs{ii};
  fil=['r4it11.c65i/nctiles_budg/' budgName '/tend/tend'];
  ncload([fil '.0001.nc'],'t0'); ncload([fil '.0001.nc'],'t1');
  tend=0*mygrid.hFacC;
  if ii>3; tend=tend(:,:,1); end;

  for tt=1:length(t0);
    tmp1=read_nctiles(['r4it11.c65i/nctiles_budg/' budgName '/tend/tend'],'tend',tt);  
    tend=tend+(t1(tt)-t0(tt))*tmp1;
  end;
  ini=read_nctiles(['r4it11.c65i/nctiles_budg/' budgName '/initial/snapshot'],'snapshot');
  fin=read_nctiles(['r4it11.c65i/nctiles_budg/' budgName '/final/snapshot'],'snapshot');

  test0=nanstd((fin-ini)-tend)/nanstd(tend);
  fprintf('%s : %3.2g \n',budgName,test0);

end;


