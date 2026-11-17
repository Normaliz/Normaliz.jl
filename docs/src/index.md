# Getting Started

Normaliz.jl is a Julia interface to [Normaliz](https://github.com/Normaliz/Normaliz),
an open source tool for computations in affine monoids, vector configurations,
lattice polytopes, and rational cones.


## Installation

To use Normaliz.jl we require Julia 1.10 or higher. Please see
<https://julialang.org/downloads/> for instructions on
how to obtain julia for your system.

To install this package, enter this into the Julia prompt:
```julia
using Pkg; Pkg.develop(url="https://github.com/Normaliz/Normaliz.jl")
```

The C++ part of the package is compiled when it is first loaded, which requires a
C++ compiler and `cmake`.


## Basic usage

A [`Cone`](@ref) is constructed from matrices, passed as keyword arguments named
after Normaliz input types, and its properties are retrieved with
[`cone_property`](@ref):

```jldoctest
julia> using Normaliz

julia> C = Cone(; cone = [1 2; 3 5], grading = [1 1])
Normaliz cone of embedding dimension 2

julia> cone_property(C, :HilbertBasis)
2×2 Matrix{BigInt}:
 1  2
 3  5

julia> cone_property(C, :EmbeddingDim)
2
```

Normaliz keeps computed properties with the cone, so asking for a property again does
not recompute it. [`is_computed`](@ref) and [`computed_cone_properties`](@ref) tell
which properties are available, and [`known_cone_properties`](@ref) lists all property
names.


## Computing properties together and choosing algorithms

[`compute!`](@ref) computes several properties in one Normaliz run, which lets Normaliz
share work between them. The results are then retrieved with `cone_property`, without
computing them again.

Both `compute!` and `cone_property` accept Normaliz flags as `Bool` keyword arguments
named after the flag, for example `DualMode = true` to use the dual algorithm instead
of the primal one:

```jldoctest
julia> using Normaliz

julia> D = Cone(; cone = [1 0; 1 3], grading = [1 0]);

julia> compute!(D, :HilbertBasis, :SupportHyperplanes; DualMode = true);

julia> cone_property(D, :SupportHyperplanes)
2×2 Matrix{BigInt}:
 0   1
 3  -1
```

Any flag known to Normaliz can be passed this way; see the section "Computation
goals and algorithmic variants" of the
[Normaliz manual](https://github.com/Normaliz/Normaliz/blob/master/doc/Normaliz.pdf).
Since a computed property is never recomputed, flags only affect properties that
have not been computed yet.


## Public API

### Cones and their properties

```@docs
Cone
cone_property
compute!
```

### Inspecting properties

```@docs
is_computed
computed_cone_properties
known_cone_properties
```
