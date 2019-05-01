using CxxWrap
using Base.Filesystem
import Pkg
import CMake

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS

jlcxx_cmake_dir = joinpath(dirname(CxxWrap.jlcxx_path), "cmake", "JlCxx")

julia_exec = joinpath(Sys.BINDIR , "julia")

run(`git clone --depth=1 https://github.com/Normaliz/Normaliz`)
cd(joinpath(@__DIR__, "Normaliz"))
run("./install_normaliz_with_eantic.sh")
normaliz_local_dir = joinpath("@__DIR__","Normaliz","local")

cd(joinpath(@__DIR__, "src"))

include_path = "-I"*joinpath(normaliz_local_dir,"include")
lib_path = joinpath(normaliz_local_dir,"lib")
lib_path = "-L"*lib_path*" -Wl,-R"*lib_path


run(`$(CMake.cmake) -DJulia_EXECUTABLE=$julia_exec -DJlCxx_DIR=$jlcxx_cmake_dir -Dnormaliz_include=$include_path -Dnormaliz_lib=$lib_path -DCMAKE_INSTALL_LIBDIR=lib .`)
run(`make -j$(div(Sys.CPU_THREADS,2))`)
