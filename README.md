[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://normaliz.github.io/Normaliz.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://normaliz.github.io/Normaliz.jl/dev)
[![Build Status](https://github.com/Normaliz/Normaliz.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/Normaliz/Normaliz.jl/actions/workflows/CI.yml)
[![Codecov](https://codecov.io/github/Normaliz/Normaliz.jl/coverage.svg?branch=master&token=)](https://codecov.io/gh/Normaliz/Normaliz.jl)

# Normaliz.jl Julia package

This repository contains the [Normaliz.jl](src/Normaliz.jl) Julia package.
It is a wrapper around [Normaliz](https://github.com/Normaliz/Normaliz), an
open source tool for computations in affine monoids, vector configurations,
lattice polytopes, and rational cones.

## Install

To install this package in Julia:
```
using Pkg; Pkg.add("Normaliz")
```

## Basic usage

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


## Contact

Issues should be reported via our [issue tracker](https://github.com/Normaliz/Normaliz.jl/issues).
