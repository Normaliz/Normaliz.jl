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

Here is an example of using Normaliz.jl:

```jldoctest
julia> using Normaliz

julia> C = Cone(; cone = [1 2; 3 5], grading = [1 1])
Normaliz cone

julia> cone_property(C, :HilbertBasis)
2×2 Matrix{BigInt}:
 1  2
 3  5

julia> cone_property(C, :EmbeddingDim)
2
```

## Public API

```@docs
Cone
cone_property
known_cone_properties
computed_cone_properties
is_computed
```
