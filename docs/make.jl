using Documenter, Normaliz

makedocs(
    format = Documenter.HTML(),
    sitename = "Normaliz.jl",
    modules = [Normaliz],
    clean = true,
    doctest = false,
    pages = [
        "index.md",
    ]
)

deploydocs(
    repo= "github.com/Normaliz/Normaliz.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)
