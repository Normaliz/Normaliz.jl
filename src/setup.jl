# Builds the C++ wrapper in deps/src on first use and whenever its inputs
# change. The build lives in deps/build-$VERSION, as different Julia versions
# are not ABI compatible, next to a stamp file recording those inputs.
module Setup

import CxxWrap
import FileWatching: Pidfile
import Libdl
import Pkg
import normaliz_jll

const DEPS_DIR = abspath(@__DIR__, "..", "deps")
const SRC_DIR = joinpath(DEPS_DIR, "src")
const BUILD_DIR = joinpath(DEPS_DIR, "build-$VERSION")
const LIB_PATH = joinpath(BUILD_DIR, "lib", "libnormaliz_julia.$(Libdl.dlext)")
const STAMP_PATH = joinpath(BUILD_DIR, "lib", "libnormaliz_julia.stamp")

# CxxWrap generates the Julia methods from the library at precompile time, so a
# change to the C++ sources must invalidate the precompile cache
include_dependency(SRC_DIR)
for (root, _, files) in walkdir(SRC_DIR), file in files
    include_dependency(joinpath(root, file))
end

cxx_coverage_enabled() =
    lowercase(get(ENV, "NORMALIZ_JL_CXX_COVERAGE", "false")) in ("1", "true", "yes", "on")

function jll_artifact_dir(the_jll::Module)
    artifacts_toml =
        joinpath(dirname(dirname(Base.pathof(the_jll))), "StdlibArtifacts.toml")

    # a stdlib JLL does not ship its headers, so download its artifact
    if isfile(artifacts_toml)
        name = replace(string(nameof(the_jll)), "_jll" => "")
        meta = Pkg.Artifacts.artifact_meta(name, artifacts_toml)
        hash = Base.SHA1(meta["git-tree-sha1"])
        if !Pkg.Artifacts.artifact_exists(hash)
            dl_info = first(meta["download"])
            Pkg.Artifacts.download_artifact(hash, dl_info["url"], dl_info["sha256"])
        end
        return Pkg.Artifacts.artifact_path(hash)
    end

    return the_jll.find_artifact_dir()
end

function libomp_path()
    @static if Sys.isbsd()
        return normaliz_jll.LLVMOpenMP_jll.get_libomp_path()
    else
        return normaliz_jll.CompilerSupportLibraries_jll.get_libgomp_path()
    end
end

# Everything the build depends on besides the sources. It also goes into the
# stamp, so an updated JLL or CxxWrap triggers a rebuild.
function cmake_args()
    coverage = cxx_coverage_enabled()
    return [
        "-DJulia_EXECUTABLE=$(joinpath(Sys.BINDIR, Base.julia_exename()))",
        "-DJlCxx_DIR=$(joinpath(CxxWrap.prefix_path(), "lib", "cmake", "JlCxx"))",
        "-DCMAKE_BUILD_TYPE=$(coverage ? "Debug" : "Release")",
        "-DNORMALIZ_JULIA_ENABLE_COVERAGE=$(coverage ? "ON" : "OFF")",
        "-Dnormaliz_prefix=$(jll_artifact_dir(normaliz_jll))",
        "-Dgmp_prefix=$(jll_artifact_dir(normaliz_jll.GMP_jll))",
        "-Dmpfr_prefix=$(jll_artifact_dir(normaliz_jll.MPFR_jll))",
        "-Dnauty_prefix=$(jll_artifact_dir(normaliz_jll.nauty_jll))",
        "-Dflint_prefix=$(jll_artifact_dir(normaliz_jll.FLINT_jll))",
        "-Dlibnormaliz_path=$(normaliz_jll.get_libnormaliz_path())",
        "-Dlibgmp_path=$(normaliz_jll.GMP_jll.get_libgmp_path())",
        "-Dlibgmpxx_path=$(normaliz_jll.GMP_jll.get_libgmpxx_path())",
        "-Dlibmpfr_path=$(normaliz_jll.MPFR_jll.get_libmpfr_path())",
        "-Dlibnauty_path=$(normaliz_jll.nauty_jll.get_libnauty_path())",
        "-Dlibflint_path=$(normaliz_jll.FLINT_jll.get_libflint_path())",
        "-Dlibomp_path=$(libomp_path())",
    ]
end

# the git tree hash, which a future libnormaliz_julia_jll will record as well
source_hash() = bytes2hex(Pkg.GitTools.tree_hash(SRC_DIR))

is_up_to_date(stamp) = isfile(LIB_PATH) && isfile(STAMP_PATH) && read(STAMP_PATH, String) == stamp

function build(args, stamp)
    @info "Compiling libnormaliz_julia"

    # use the system cmake: CMake_jll puts Julia's private libdir on
    # LD_LIBRARY_PATH, and on Julia 1.10 its libstdc++ is older than the one a
    # system compiler or ccache needs ("CXXABI_1.3.15 not found")
    Sys.which("cmake") === nothing &&
        error("Could not locate 'cmake' binary, needed to build libnormaliz_julia")

    rm(BUILD_DIR; force = true, recursive = true)

    # JlCxx's cmake config runs Julia_EXECUTABLE; keep our load path out of it
    withenv("JULIA_LOAD_PATH" => nothing) do
        run(`cmake $args -S $SRC_DIR -B $BUILD_DIR`)
        run(`cmake --build $BUILD_DIR --config $(cxx_coverage_enabled() ? "Debug" : "Release")
             -- -j$(max(1, div(Sys.CPU_THREADS, 2)))`)
    end

    write(STAMP_PATH, stamp)
end

function locate_libnormaliz_julia()
    args = cmake_args()
    stamp = join([source_hash(); args], "\n") * "\n"
    is_up_to_date(stamp) && return LIB_PATH

    # another process may be building the same library
    Pidfile.mkpidlock("$BUILD_DIR.lock"; stale_age = 60) do
        is_up_to_date(stamp) || build(args, stamp)
    end

    return LIB_PATH
end

end # module
