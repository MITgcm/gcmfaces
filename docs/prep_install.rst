
.. _install:

Install And Get Started
=======================

.. _soft:

Software Installation
---------------------

The recommended approach consists in downloading the latest and software
version from github via https://github.com/gaelforget. The code can be
downloaded either via a web-browser by using the github interface or via
the command line by typing:

::

    git clone https://github.com/gaelforget/gcmfaces
    git clone https://github.com/gaelforget/MITprof

It can later be updated, e.g., by typing git pull at the command line.

| Alternatively, if needed, earlier versions of the code can be
  downloaded directly from
| `c66e_gcmfaces.tar <http://mit.ecco-group.org/opendap/ecco_for_las/version_4/checkpoints/>`__
  and
  `c66e_MITprof.tar <http://mit.ecco-group.org/opendap/ecco_for_las/version_4/checkpoints/>`__
  or via the CVS server where the initial development phase, through
  2016, is documented. In the latter case, one logs into the CVS server
  as explained @ http://mitgcm.org/public/using_cvs.html and then types:

::

    cvs co -P -r checkpoint66b -d gcmfaces MITgcm_contrib/gael/matlab_class
    cvs co -P -r checkpoint66b -d MITprof MITgcm_contrib/gael/profilesMatlabProcessing

.. _data:

Data Downloads
--------------

To get started (sections `1.3 <#getting started>`__ and
`[features] <#features>`__) one downloads the LLC90 grid
(‘nctiles_grid/’; 145M) either from the `MIT ftp
server <ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/nctiles_grid/>`__
or from its `Dataverse permanent
archive <http://dx.doi.org/10.7910/DVN/H8W5VW>`__. To illustrate
higher-level functions, sections \ `[demo] <#demo>`__
and \ `[standard] <#standard>`__ rely on the ECCO v4 r2 ocean state
estimate :raw-latex:`\citep{dspace-eccov4r2}` directories as shown in
Fig. \ `[getting started tree] <#getting started tree>`__. The relevant
files can be downloaded from the `Dataverse permanent
archive <https://dataverse.harvard.edu/dataverse/ECCOv4r2>`__ or from
the `MIT ftp
server <ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/>`__,
e.g., using commands reported in Fig. \ `[downloads] <#downloads>`__.

Downloading ‘nctiles_climatology/’ (10G), ‘nctiles_grid/’ (145M), and
the Matlab code (, , and ) suffices for the basic purposes of
section \ `[demo] <#demo>`__ and \ `[standard] <#standard>`__. The files
in ‘profiles/’ (7G) and ‘nctiles_remotesensing/’ (27G)allow for
model-data comparisons. The ‘nctiles_monthly/’ directory contains the
full 1992-2011 ECCO v4 r2 monthly time series (170G) and can be used to
reproduce the :raw-latex:`\cite{dspace-eccov4r2}` plots as explained in
section \ `[standard] <#standard>`__.

.. _getting started:

Get Started
-----------

Once ‘gcmfaces/’, ‘MITprof/’, and ‘nctiles_grid/’ have been placed in a
common directory (‘./’ in
Fig. \ `[getting started tree] <#getting started tree>`__), one may
simply open Matlab from that directory and type:

::

    %add gcmfaces and MITprof directories to Matlab path:
    p = genpath('gcmfaces/'); addpath(p);
    p = genpath('MITprof/'); addpath(p);

    %load all grid variables from nctiles_grid/ into mygrid:
    grid_load; 

    %make mygrid accessible in current workspace:
    gcmfaces_global;

    %display list of grid variables:
    disp(mygrid);

    %display one gcmfaces variable:
    disp(mygrid.XC);

.. raw:: latex

   \dirtree{%
   .1 ./.
   .2 gcmfaces/ (Matlab toolbox).
   .2 MITprof/ (Matlab toolbox).
   .2 m\_map/ (Matlab toolbox).
   .2 nctiles\_grid/ (netcdf files).
   .2 release2\_climatology/.
   .3 nctiles\_climatology/.
   .3 mat/ (see section 5).
   .3 tex/ (see section 5).
   .2 release2/.
   .3 nctiles\_monthly/.
   .3 nctiles\_remotesensing/).
   .3 profiles/.
   .3 mat/ (see section 5).
   .3 tex/ (see section 5).
   }

[getting started tree]

::

    setenv FTPv4r2 'ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/'
    #export FTPv4r2='ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/'
    wget --recursive {$FTPv4r2}/nctiles_grid
    wget --recursive {$FTPv4r2}/nctiles_climatology
    wget --recursive {$FTPv4r2}/nctiles_monthly
    wget --recursive {$FTPv4r2}/nctiles_remotesensing
    wget --recursive {$FTPv4r2}/profiles

[downloads]
