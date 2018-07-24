
.. _features:

Basic Features
==============

The core of `gcmfaces` lies in (1) its representation of connected arrays, or faces, as 
objects of the class defined in the ``@gcmfaces/`` directory (see :numref:`class`)
and (2) its handling of C-Grid specifications via the `mygrid` global structure
(:numref:`Cgrid`). Other basic features include functions that `exchange` data 
between faces (:numref:`exch`), or `overload` common operations (:numref:`overload`),
as well as I/O routines (:numref:`formats`). These and other `gcmfaces` functions are generally 
documented through help sections that are readily accessible via the Matlab or Octave command window.

.. _class:

The gcmfaces Class
------------------

:numref:`sphere_all` illustrates four types of grids that are
have been used in ocean general circulation models. Despite evident
design differences, these grids can all be represented as sets of
connected arrays, or faces, as shown in :numref:`plot_one_field_FACES` 
in the case of the LLC90 grid. `gcmfaces` simply takes advantage of this fact 
by defining a class for these objects, within ``@gcmfaces/``, that represents 
gridded earth variables generically as sets of connected arrays.

Grid specifics, such as the number of faces and the size of each face, 
are embedded within the `gcmfaces` objects (see :ref:`gcmfaces_object`).
Objects of the `gcmfaces` class can thus be manipulated simply through compact 
and generic expressions such as `a+b` that are robust to changes in grid
design (:numref:`sphere_all`). The `gcmfaces` class inherits many of its
basic operations from the `double` class as illustrated for the
:ref:`plus_function` (see :numref:`overload` for details).

.. figure:: figs/fig12-eccov4.pdf
   :width: 85%
   :align: center
   :alt: Ocean topography on the LLC90 grid displayed face by face
   :name: plot_one_field_FACES

   Ocean topography on the LLC90 grid (:numref:`sphere_all`, bottom
   right) displayed face by face (going from 1 to 5). This plot
   generated using example_display(1) illustrates how gcmfaces organizes
   data in memory (see :ref:`gcmfaces_object`). Within each face, grid point
   indices increase from left to right and bottom to top.

.. _gcmfaces_object:

.. rubric:: Gcmfaces object structure

An Earth variable on the LLC90 grid (:numref:`sphere_all`, bottom right) stored as a `gcmfaces` 
object called `fld` has the data structure depicted below. In this example, `fld` is a two dimensional field, and
the five face arrays plotted in :numref:`plot_one_field_FACES` are denoted as f1 to f5.

::

    fld
      nFaces: 5
      f1: [90x270 double]
      f2: [90x270 double]
      f3: [90x90 double]
      f4: [270x90 double]
      f5: [270x90 double]
 
.. _Cgrid:

Handling C-Grids
----------------

In practice `gcmfaces` gets activated by adding, to the
least, the ``@gcmfaces/`` directory to the Matlab path and then loading a
grid to memory (:numref:`getting_started`). The default grid is LLC90, 
which can be loaded to memory by calling ``grid_load.m`` without any
argument. :numref:`formats` and ``help grid_load;`` provide
additional information regarding, respectively, and supported file 
formats and ``grid_load.m`` arguments. As an alternative to 
``grid_load.m``, `MITgcm` input grid files can be read ``grid_load_native.m`` 
as shown `here <http://mit.ecco-group.org/opendap/ecco_for_las/version_4/grids/grids_input/>`__
(see README and ``demo_grids.m``).

Both ``grid_load.m`` and ``grid_load_native.m`` store all C-grid variables 
at once in a global variable named `mygrid` (:numref:`mygrid`). `gcmfaces`
functions then rely on `mygrid` that they get access to by calling
``gcmfaces_global.m`` which also returns system information via `myenv`. If
these global variables get deleted at some point, for example by a call to 
``clear all;``, user may need to rerun ``grid_load.m`` or ``grid_load_native.m``. 
In such situtations, any call to ``gcmfaces_global.m`` will generate a warning 
that `mygrid has not yet been loaded to memory`.

.. table:: List of grid variables available via the mygrid global
           variable. The naming convention is directly inherited from the `MITgcm`
           naming convention [1]_.
  :name: mygrid

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

The C-grid variable names listed in :numref:`mygrid` derive from the `MITgcm` 
naming convention [1]_. In brief, XC, YC, and RC denote longitude, latitude, and
vertical position of tracer variable locations. DXC, DYC, DRC and RAC
are the corresponding grid spacings, in m, and grid cell areas, in
m\ :math:`^2`. A different set of such variables (XG, YG, RF, DXG, DYG,
DRF, RAZ) corresponds to velocity and vorticity variables that are
staggered in the C-grid approach [1]_.

Indexing and vector orientation conventions also derive from 
`MITgcm` conventions [1]_. The indexing convention is illustrated in
:numref:`plot_one_field_FACES`. For vector
fields, the first component (U) is directed toward the right of the page
and the second component (V) toward the top of the page. As compared
with tracers, velocity variable locations are shifted by half a grid
point to the left of the page (U components) or the bottom of the page
(V components) following the C-grid approach [1]_.

.. _exch:

Exchange Functions
------------------

Many computations of interest (e.g., gradients and flow convergences)
involve values from nearby grid points on neighboring faces. In
practice rows and columns need to be appended at each face edge that are
`exchanged` between neighboring faces – e.g., rows and columns from
faces #2, #3, and #5 need to be appended at the face #1 edges in
:numref:`plot_one_field_FACES`. Exchanges are
operated by ``exch_T_N.m`` for tracer-type variables and by ``exch_UV_N.m`` for
velocity-type variables. These are notably used to compute gradients
(``calc_T_grad.m``) and flow convergences (``calc_UV_conv.m``).

.. _overload:

Overloaded Functions
--------------------

As in the case of the :ref:`plus_function`, common operations and functions 
are overloaded as part of the gcmfaces class definition
within the ``@gcmfaces/`` directory:

#. Logical operators: and, eq, ge, gt, isnan, le, lt, ne, not, or.

#. Numerical operators: abs, angle, cat, cos, cumsum, diff, exp, imag,
   log2, max, mean, median, min, minus, mrdivide, mtimes, nanmax,
   nanmean, nanmedian, nanmin, nanstd, nansum, plus, power, rdivide,
   real, sin, sqrt, std, sum, tan, times, uminus, uplus.

#. Indexing operators: subsasgn, subsref, find, get, set, squeeze,
   repmat.

It may be worth highlighting ``@gcmfaces/subsasgn.m`` (subscripted
assignment) and ``@gcmfaces/subsref.m`` (subscripted reference) since they 
overload some of the most commonly used Matlab functions. For example, if 
`fld` is of the `double` class then ``tmp2=fld(1);`` and ``fld(1)=1;`` call 
``subsref.m`` and ``subsasgn.m``, respectively. If `fld` instead is of the 
gcmfaces class then ``@gcmfaces/subsref.m`` behaves as follows:

::

    fld{n}     returns the n^{th} face data (i.e., an array).
    fld(:,:,n) returns the n^{th} vertical level (i.e., a gcmfaces object).

and ``@gcmfaces/subsasgn.m`` behaves similarly but for assignments.

.. _plus_function:

.. rubric:: Overloaded + function

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

.. _formats:

Input / Output Files
--------------------

Objects of the `gcmfaces` class can readily be saved to file using
Matlab’s proprietary I/O format (`.mat` files). Reloading them in a
later Matlab session works seamlessly as long as the gcmfaces class 
has been defined by including ``@gcmfaces/`` to the Matlab path.

Alternatively, gcmfaces variables can be written to files in the
`nctiles` format :cite:`for-eta:15`. Illustrations in
this user guide rely upon ECCO version 4 fields which are distributed in this
format (see :numref:`data`; :ref:`gcmfaces_demo_dirtree` and :ref:`downloads`).
The associated I/O functions provided in `gcmfaces` (``write2nctiles.m`` and
``read_nctiles.m``) reformat data on the fly.

Finally, `gcmfaces` can read MITgcm binary output in the `mds` format [2]_.
The provided I/O functions (``rdmds2gcmfaces.m`` and ``read_bin.m``) rely on
``convert2gcmfaces.m`` to convert `mds` output to `gcmfaces` objects on the fly.
The reverse conversion occurs when ``convert2gcmfaces.m`` is called with a `gcmfaces`
input argument. This approach provides a unified framework to analyze MITgcm output or 
prepare MITgcm input for `all known grids <http://mit.ecco-group.org/opendap/ecco_for_las/version_4/grids/grids_output/contents.html>`__
(see README and ``demo_grids.m``).

.. [1]
   For details, see sections 2.11 and 6.2.4 in http://mitgcm.org/public/r2_manual/latest/online_documents/manual.pdf

.. [2]
   For details, see section 7.3 in http://mitgcm.org/public/r2_manual/latest/online_documents/manual.pdf
