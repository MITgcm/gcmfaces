
.. _features:

The Basic gcmfaces Features
===========================

The core of lies in its handling of connected arrays/faces via a new
Matlab class/variable type (section `1.1 <#class>`__) and its handling
of C-Grid specifications via the global variable
(section `1.2 <#grid_load.m>`__). Basic features of also include
functions that ‘exchange’ data between faces (section `1.3 <#exch>`__),
‘overloaded’ operations (section `1.4 <#overload>`__), and I/O functions
(section `1.5 <#formats>`__). functions are normally documented via help
sections that are accessible within Matlab.

.. _class:

The gcmfaces Class
------------------

:numref:`sphere_all` illustrates four types of grids that are
commonly used in general circulation models (GCMs). Despite evident
design differences, these grids can all be represented as sets of
connected arrays (‘faces’) as illustrated in
:numref:`plot_one_field_FACES` for the LLC90
grid. simply takes advantage of this fact by defining an additional
Matlab class, within @gcmfaces/, to represent gridded earth variables
generically as sets of connected arrays.

Grid specifics, such as the number of faces and grid points, are
embedded within objects as illustrated in Table \ `[fld] <#fld>`__.
Objects of the class can thus be manipulated simply through compact and
generic expressions such as ‘a+b’ that are robust to changes in grid
design (:numref:`sphere_all`). The class inherits many of its basic
operations (see section \ `1.4 <#overload>`__ for details) from the
‘double’ class as illustrated in Table \ `[plus] <#plus>`__ for .

.. figure:: figs/fig12-eccov4.pdf
   :width: 95%
   :align: center
   :alt: Ocean topography on the LLC90 grid displayed face by face
   :name: plot_one_field_FACES

   Ocean topography on the LLC90 grid (:numref:`sphere_all`, bottom
   right) displayed face by face (going from 1 to 5). This plot
   generated using example_display(1) illustrates how gcmfaces organizes
   data in memory (Tab. `[fld] <#fld>`__). Within each face, grid point
   indices increase from left to right and bottom to top.

.. table:: Earth variable on the LLC90 grid (:numref:`sphere_all`,
bottom right) represented as an object of the gcmfaces class
(@gcmfaces/). The five face arrays (going from f1 to f5) are depicted in
:numref:`plot_one_field_FACES` accordingly.

   +-------+---------+-----------------+
   | fld = |         |                 |
   +-------+---------+-----------------+
   |       | nFaces: | 5               |
   +-------+---------+-----------------+
   |       | f1:     | [90x270 double] |
   +-------+---------+-----------------+
   |       | f2:     | [90x270 double] |
   +-------+---------+-----------------+
   |       | f3:     | [90x90 double]  |
   +-------+---------+-----------------+
   |       | f4:     | [270x90 double] |
   +-------+---------+-----------------+
   |       | f5:     | [270x90 double] |
   +-------+---------+-----------------+

[fld]

::

    function r = plus(p,q)
    %overloaded gcmfaces `+' function :
    %  simply calls double `+' function for each face data
    %  if any of the two arguments is a gcmfaces object

    if isa(p,'gcmfaces'); r=p; else; r=q; end;
    for iFace=1:r.nFaces;
       iF=num2str(iFace);
       if isa(p,'gcmfaces')&isa(q,'gcmfaces');
           eval(['r.f' iF '=p.f' iF '+q.f' iF ';']);
       elseif isa(p,'gcmfaces')&isa(q,'double');
           eval(['r.f' iF '=p.f' iF '+q;']);
       elseif isa(p,'double')&isa(q,'gcmfaces');
           eval(['r.f' iF '=p+q.f' iF ';']);
       else;
          error('gcmfaces plus: types are incompatible')
       end;
    end;

[plus]

.. _grid_load.m:

C-Grid Variables
----------------

In practice the gcmfaces framework gets activated by adding, to the
least, the @gcmfaces/ directory to the Matlab path and then loading a
grid to memory as done in
section \ `[getting started] <#getting started>`__. The default, LLC90,
grid can be loaded to memory by calling grid_load.m without any
argument. ‘help grid_load.m’ and section \ `1.5 <#formats>`__ provide
additional information regarding, respectively grid_load.m arguments and
supported file formats. Alternatively, grids can be read from MITgcm
input files using grid_load_native.m as shown in `this
webpage <http://mit.ecco-group.org/opendap/ecco_for_las/version_4/grids/grids_input/>`__
(see README and demo_grids.m).

grid_load.m and grid_load_native.m store all C-grid variables at once in
a global variable named mygrid (Tab. `[mygrid] <#mygrid>`__). gcmfaces
functions often rely on mygrid that they access via a call to
gcmfaces_global.m which also provides system information via myenv. If
these global variables get deleted, typically by a ‘clear all’, then
another call to grid_load.m is generally needed. gcmfaces_global.m will
indicate this situation to the user by issuing warnings that ‘mygrid has
not yet been loaded to memory’.

.. table:: List of grid variables available via the mygrid global
variable. The naming convention is directly inherited from the MITgcm
naming convention. For details, see sections 2.11 and 6.2.4 in
http://mitgcm.org/public/r2_manual/latest/online_documents/manual.pdf

   +---------+---+----------------+------------------------------------------+
   | XC      | : | [1x1 gcmfaces] | longitude (tracer)                       |
   +---------+---+----------------+------------------------------------------+
   | YC      | : | [1x1 gcmfaces] | latitude (tracer)                        |
   +---------+---+----------------+------------------------------------------+
   | RC      | : | [50x1 double]  | depth (tracer)                           |
   +---------+---+----------------+------------------------------------------+
   | XG      | : | [1x1 gcmfaces] | longitude (vorticity)                    |
   +---------+---+----------------+------------------------------------------+
   | YG      | : | [1x1 gcmfaces] | latitude (vorticity)                     |
   +---------+---+----------------+------------------------------------------+
   | RF      | : | [51x1 double]  | depth (velocity along 3rd dim)           |
   +---------+---+----------------+------------------------------------------+
   | DXC     | : | [1x1 gcmfaces] | grid spacing (tracer, 1st dim)           |
   +---------+---+----------------+------------------------------------------+
   | DYC     | : | [1x1 gcmfaces] | grid spacing (tracer, 2nd dim)           |
   +---------+---+----------------+------------------------------------------+
   | DRC     | : | [50x1 double]  | grid spacing (tracer, 3nd dim)           |
   +---------+---+----------------+------------------------------------------+
   | RAC     | : | [1x1 gcmfaces] | grid cell area (tracer)                  |
   +---------+---+----------------+------------------------------------------+
   | DXG     | : | [1x1 gcmfaces] | grid spacing (vorticity, 1st dim)        |
   +---------+---+----------------+------------------------------------------+
   | DYG     | : | [1x1 gcmfaces] | grid spacing (vorticity, 2nd dim)        |
   +---------+---+----------------+------------------------------------------+
   | DRF     | : | [50x1 double]  | grid spacing (velocity, 3nd dim)         |
   +---------+---+----------------+------------------------------------------+
   | RAZ     | : | [1x1 gcmfaces] | grid cell area (vorticity)               |
   +---------+---+----------------+------------------------------------------+
   | AngleCS | : | [1x1 gcmfaces] | grid orientation (tracer, cosine)        |
   +---------+---+----------------+------------------------------------------+
   | AngleSN | : | [1x1 gcmfaces] | grid orientation (tracer, cosine)        |
   +---------+---+----------------+------------------------------------------+
   | Depth   | : | [1x1 gcmfaces] | ocean bottom depth (tracer)              |
   +---------+---+----------------+------------------------------------------+
   | hFacC   | : | [1x1 gcmfaces] | partial cell factor (tracer)             |
   +---------+---+----------------+------------------------------------------+
   | hFacS   | : | [1x1 gcmfaces] | partial cell factor (velocity, 2nd dim)  |
   +---------+---+----------------+------------------------------------------+
   | hFacW   | : | [1x1 gcmfaces] | partial cell factor (velocity, 1rst dim) |
   +---------+---+----------------+------------------------------------------+

[mygrid]

The C-grid variable names listed in Tab. \ `[mygrid] <#mygrid>`__ derive
from the  [1]_. In brief, XC, YC, and RC denote longitude, latitude, and
vertical position of tracer variable locations. DXC, DYC, DRC and RAC
are the corresponding grid spacings, in m, and grid cell areas, in
m\ :math:`^2`. A different set of such variables (XG, YG, RF, DXG, DYG,
DRF, RAZ) corresponds to velocity and vorticity variables that are
staggered in a C-grid approach\ :sup:``[manual] <#manual>`__`.

Indexing and vector orientation conventions also derive from the
:sup:``[manual] <#manual>`__`. The indexing convention is illustrated in
:numref:`plot_one_field_FACES`. For vector
fields, the first component (U) is directed toward the right of the page
and the second component (V) toward the top of the page. As compared
with tracers, velocity variable locations are shifted by half a grid
point to the left of the page (U components) or the bottom of the page
(V components) following the C-grid
approach\ :sup:``[manual] <#manual>`__`.

.. _exch:

Exchange Functions
------------------

Many computations of interest (e.g., gradients and flow convergences)
involve values from contiguous grid points on neighboring faces. In
practice rows and columns need to be appended at each face edge that are
‘exchanged’ between neighboring faces – e.g., rows and columns from
faces #2, #3, and #5 at the face #1 edges in
:numref:`plot_one_field_FACES`. Exchanges are
operated by exch_T_N.m for tracer-type variables and by exch_UV_N.m for
velocity-type variables. They are used to compute gradients
(calc_T_grad.m and flow convergences (calc_UV_conv.m) in
sections \ `[demo] <#demo>`__ and \ `[standard] <#standard>`__.

.. _overload:

Overloaded Functions
--------------------

As illustrated for the ‘+’ operation in Table \ `[plus] <#plus>`__,
common functions are overloaded as part of the gcmfaces class definition
within the @gcmfaces/ directory:

#. Logical operators: and, eq, ge, gt, isnan, le, lt, ne, not, or.

#. Numerical operators: abs, angle, cat, cos, cumsum, diff, exp, imag,
   log2, max, mean, median, min, minus, mrdivide, mtimes, nanmax,
   nanmean, nanmedian, nanmin, nanstd, nansum, plus, power, rdivide,
   real, sin, sqrt, std, sum, tan, times, uminus, uplus.

#. Indexing operators: subsasgn, subsref, find, get, set, squeeze,
   repmat.

| It may be worth highlighting @gcmfaces/subsasgn.m (subscripted
  assignment) and
| @gcmfaces/subsref.m (subscripted reference) since they overload some
  of the most commonly used Matlab functions. For example, if fld is of
  the ‘double’ class then ‘tmp2=fld(1);’ and ‘fld(1)=1;’ call subsref.m
  and subsasgn.m, respectively. If fld instead is of the gcmfaces class
  then @gcmfaces/subsref.m behaves as follows:

::

    fld{n}     returns the n^{th} face data (i.e., an array).
    fld(:,:,n) returns the n^{th} vertical level (i.e., a gcmfaces object).

and @gcmfaces/subsasgn.m behaves similarly but for assignments.

.. _formats:

I/O Functions
-------------

Objects of the gcmfaces class can readily be saved to file using
Matlab’s proprietary I/O format (‘.mat’ files). Reloading them in a
later Matlab session works seamlessly as long as the gcmfaces class has
been defined by including @gcmfaces/ in the Matlab path.

Alternatively, gcmfaces variables can be written to files in the
‘nctiles’ format :raw-latex:`\citep{gmd-8-3071-2015}`. Illustrations in
this user guide rely upon ECCO v4 fields which are distributed in this
format (see section \ `[data] <#data>`__;
Figs. \ `[getting started tree] <#getting started tree>`__-`[downloads] <#downloads>`__).
The I/O functions provided as part of gcmfaces (write2nctiles.m and
read_nctiles.m) reformat data on the fly.

gcmfaces can also read MITgcm binary output in the ‘mds’ format [2]_.
The provided I/O functions (rdmds2gcmfaces.m and read_bin.m) rely on
convert2gcmfaces.m to reformat data on the fly. gcmfaces thus readily
provides a common tool to analyze any of the `ECCO
solutions <http://ecco-group.org/products.htm>`__ as illustrated in
`this
webpage <http://mit.ecco-group.org/opendap/ecco_for_las/version_4/grids/grids_output/contents.html>`__
(see README and demo_grids.m).

.. [1]
   [manual]For details, see sections 2.11 and 6.2.4 in
   http://mitgcm.org/public/r2_manual/latest/online_documents/manual.pdf

.. [2]
   For details, see section 7.3 in
   http://mitgcm.org/public/r2_manual/latest/online_documents/manual.pdf
