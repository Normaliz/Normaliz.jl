using CxxWrap
import CMake_jll

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS

jlcxx_cmake_dir = joinpath(CxxWrap.prefix_path(), "lib", "cmake", "JlCxx")

julia_exec = joinpath(Sys.BINDIR , "julia")

normaliz_local_dir=""

if !haskey(ENV,"NORMALIZ_LOCAL_DIR")
    normaliz_dir = joinpath(@__DIR__, "Normaliz")
    # isdir(normaliz_dir) && rm(normaliz_dir, recursive=true)
    # run(`git clone --depth=1 https://github.com/Normaliz/Normaliz`)
    # cd(normaliz_dir)
    # run(`./install_normaliz_with_eantic.sh`)
    normaliz_local_dir = joinpath(@__DIR__,"Normaliz","local")
else
    normaliz_local_dir = ENV["NORMALIZ_LOCAL_DIR"]
end

include_path = joinpath(normaliz_local_dir,"include")
lib_path = joinpath(normaliz_local_dir,"lib")

# basic compiler and linker flags
compiler_flags = [
    "-I$include_path",
    ]
linker_flags = [
    "-L$lib_path",
    # setup rpath so that right copy of libnormaliz is found and linked:
    "-Wl,-rpath,$lib_path"
    ]

# honor GMP_INSTALLDIR
gmpdir = get(ENV, "GMP_INSTALLDIR", nothing)
if gmpdir !== nothing
    push!(compiler_flags, "-I$gmpdir/include")
    push!(linker_flags, "-L$gmpdir/lib")
end

cd(joinpath(@__DIR__, "src"))
builddir = "build"

# delete any previous build, so we rebuild from scratch
rm(builddir; force=true, recursive=true)

CMake_jll.cmake() do exe
  run(`$exe
      -DJulia_EXECUTABLE=$julia_exec
      -DJlCxx_DIR=$jlcxx_cmake_dir
      -Dnormaliz_include=$(join(compiler_flags, " "))
      -Dnormaliz_lib=$(join(linker_flags, " "))
      -DCMAKE_INSTALL_LIBDIR=lib
      -B $(builddir)
      -S .
  `)
  run(`$exe
      --build $(builddir)
      --config Release
      --
      -j$(div(Sys.CPU_THREADS,2))
  `)

end
