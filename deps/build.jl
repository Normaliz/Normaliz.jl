using CxxWrap
import CMake_jll
using Pkg.Artifacts

using normaliz_jll

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS

jlcxx_cmake_dir = joinpath(CxxWrap.prefix_path(), "lib", "cmake", "JlCxx")
julia_exec = joinpath(Sys.BINDIR, Base.julia_exename())

function jll_artifact_dir(the_jll::Module)
    artifacts_toml = joinpath(dirname(dirname(Base.pathof(the_jll))), "StdlibArtifacts.toml")

    # If this file exists, it's a stdlib JLL and we must download the artifact ourselves
    if isfile(artifacts_toml)
        # the artifact name is always equal to the module name minus the "_jll" suffix
        name = replace(string(nameof(the_jll)), "_jll" => "")
        meta = artifact_meta(name, artifacts_toml)
        hash = Base.SHA1(meta["git-tree-sha1"])
        if !artifact_exists(hash)
            dl_info = first(meta["download"])
            download_artifact(hash, dl_info["url"], dl_info["sha256"])
        end
        return artifact_path(hash)
    end

    # Otherwise, we can just use the artifact directory given to us by GMP_jll
    return the_jll.find_artifact_dir()
end

cd(joinpath(@__DIR__, "src"))
builddir = "build"

# delete any previous build, so we rebuild from scratch
rm(builddir; force=true, recursive=true)

@static if Sys.isbsd()
  using normaliz_jll.LLVMOpenMP_jll
  libomp_path = normaliz_jll.LLVMOpenMP_jll.get_libomp_path()
else
  using normaliz_jll.CompilerSupportLibraries_jll
  libomp_path = normaliz_jll.CompilerSupportLibraries_jll.get_libgomp_path()
end

CMake_jll.cmake() do exe
  run(`$exe
      -DJulia_EXECUTABLE=$julia_exec
      -DJlCxx_DIR=$jlcxx_cmake_dir
      -DCMAKE_BUILD_TYPE=Release
      -Dnormaliz_prefix=$(jll_artifact_dir(normaliz_jll))
      -Dgmp_prefix=$(jll_artifact_dir(normaliz_jll.GMP_jll))
      -Dmpfr_prefix=$(jll_artifact_dir(normaliz_jll.MPFR_jll))
      -Dnauty_prefix=$(jll_artifact_dir(normaliz_jll.nauty_jll))
      -Dflint_prefix=$(jll_artifact_dir(normaliz_jll.FLINT_jll))
      -Dlibnormaliz_path=$(normaliz_jll.get_libnormaliz_path())
      -Dlibgmp_path=$(normaliz_jll.GMP_jll.get_libgmp_path())
      -Dlibgmpxx_path=$(normaliz_jll.GMP_jll.get_libgmpxx_path())
      -Dlibmpfr_path=$(normaliz_jll.MPFR_jll.get_libmpfr_path())
      -Dlibnauty_path=$(normaliz_jll.nauty_jll.get_libnauty_path())
      -Dlibflint_path=$(normaliz_jll.FLINT_jll.get_libflint_path())
      -Dlibomp_path=$libomp_path
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

# force new precompilation
touch(joinpath(@__DIR__, "..", "src", "Normaliz.jl"))
