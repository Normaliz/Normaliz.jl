# Getting Started

Normaliz.jl is a Julia interface to [Normaliz](https://github.com/Normaliz/Normaliz),
an open source tool for computations in affine monoids, vector configurations,
lattice polytopes, and rational cones.


## Installation

To use Normaliz.jl we require Julia 1.6 or higher. Please see
<https://julialang.org/downloads/> for instructions on
how to obtain julia for your system.

At the Julia prompt simply type

```
julia> using Pkg
julia> Pkg.add("Normaliz")
```

Here is an example of using Normaliz.jl:

```julia
julia> using Normaliz

julia> xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 2 ; 3 5])
2×2 Normaliz.NmzMatrixAllocated{Normaliz.NmzRational}:
 1  2
 3  5

julia> yy = Normaliz.LongLongCone( Dict( :cone => xx ) )
Normaliz cone

julia> Normaliz.get_matrix_cone_property( yy, "ExtremeRays" )
2×2 Normaliz.NmzMatrixAllocated{Int64}:
 1  2
 3  5

julia> Normaliz.get_matrix_cone_property( yy, "SupportHyperplanes" )
2×2 Normaliz.NmzMatrixAllocated{Int64}:
 -5   3
  2  -1
```
