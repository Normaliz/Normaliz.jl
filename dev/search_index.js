var documenterSearchIndex = {"docs":
[{"location":"#Getting-Started","page":"Getting Started","title":"Getting Started","text":"","category":"section"},{"location":"","page":"Getting Started","title":"Getting Started","text":"Normaliz.jl is a Julia interface to Normaliz, an open source tool for computations in affine monoids, vector configurations, lattice polytopes, and rational cones.","category":"page"},{"location":"#Installation","page":"Getting Started","title":"Installation","text":"","category":"section"},{"location":"","page":"Getting Started","title":"Getting Started","text":"To use Normaliz.jl we require Julia 1.6 or higher. Please see https://julialang.org/downloads/ for instructions on how to obtain julia for your system.","category":"page"},{"location":"","page":"Getting Started","title":"Getting Started","text":"At the Julia prompt simply type","category":"page"},{"location":"","page":"Getting Started","title":"Getting Started","text":"julia> using Pkg\njulia> Pkg.add(\"Normaliz\")","category":"page"},{"location":"","page":"Getting Started","title":"Getting Started","text":"Here is an example of using Normaliz.jl:","category":"page"},{"location":"","page":"Getting Started","title":"Getting Started","text":"julia> using Normaliz\n\njulia> xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 2 ; 3 5])\n2×2 Normaliz.NmzMatrixAllocated{Normaliz.NmzRational}:\n 1  2\n 3  5\n\njulia> yy = Normaliz.LongLongCone( Dict( :cone => xx ) )\nNormaliz cone\n\njulia> Normaliz.get_matrix_cone_property( yy, \"ExtremeRays\" )\n2×2 Normaliz.NmzMatrixAllocated{Int64}:\n 1  2\n 3  5\n\njulia> Normaliz.get_matrix_cone_property( yy, \"SupportHyperplanes\" )\n2×2 Normaliz.NmzMatrixAllocated{Int64}:\n -5   3\n  2  -1","category":"page"}]
}
