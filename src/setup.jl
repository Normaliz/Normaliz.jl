module Setup

import CMake_jll
import CxxWrap
import Libdl
import Pkg
import Pkg.Artifacts
import SHA
import normaliz_jll

function enabled(envvar::String)
    return lowercase(get(ENV, envvar, "false")) in ("1", "true", "yes", "on")
end

cxx_coverage_enabled() = enabled("NORMALIZ_JL_CXX_COVERAGE")

function jll_artifact_dir(the_jll::Module)
    artifacts_toml =
        joinpath(dirname(dirname(Base.pathof(the_jll))), "StdlibArtifacts.toml")

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

function source_files(srcdir::String)
    files = String[]
    for (root, dirs, filenames) in walkdir(srcdir)
        filter!(dirs) do dir
            return !(dir == "build" || startswith(dir, "build-"))
        end
        for filename in filenames
            push!(files, relpath(joinpath(root, filename), srcdir))
        end
    end
    return sort!(files)
end

function source_hash(srcdir::String)
    buf = IOBuffer()
    for file in source_files(srcdir)
        write(buf, file)
        write(buf, '\0')
        write(buf, read(joinpath(srcdir, file)))
        write(buf, '\0')
    end
    return bytes2hex(SHA.sha1(take!(buf)))
end

function build_key(srcdir::String)
    jlcxx_cmake_dir = joinpath(CxxWrap.prefix_path(), "lib", "cmake", "JlCxx")
    julia_exec = joinpath(Sys.BINDIR, Base.julia_exename())
    coverage = cxx_coverage_enabled()
    entries = [
        "source_hash=$(source_hash(srcdir))",
        "julia_version=$(VERSION)",
        "host_triplet=$(Base.BinaryPlatforms.host_triplet())",
        "julia_exec=$(julia_exec)",
        "jlcxx_cmake_dir=$(jlcxx_cmake_dir)",
        "coverage=$(coverage)",
        "normaliz_prefix=$(jll_artifact_dir(normaliz_jll))",
        "gmp_prefix=$(jll_artifact_dir(normaliz_jll.GMP_jll))",
        "mpfr_prefix=$(jll_artifact_dir(normaliz_jll.MPFR_jll))",
        "nauty_prefix=$(jll_artifact_dir(normaliz_jll.nauty_jll))",
        "flint_prefix=$(jll_artifact_dir(normaliz_jll.FLINT_jll))",
        "libnormaliz_path=$(normaliz_jll.get_libnormaliz_path())",
        "libgmp_path=$(normaliz_jll.GMP_jll.get_libgmp_path())",
        "libgmpxx_path=$(normaliz_jll.GMP_jll.get_libgmpxx_path())",
        "libmpfr_path=$(normaliz_jll.MPFR_jll.get_libmpfr_path())",
        "libnauty_path=$(normaliz_jll.nauty_jll.get_libnauty_path())",
        "libflint_path=$(normaliz_jll.FLINT_jll.get_libflint_path())",
        "libomp_path=$(libomp_path())",
    ]
    return join(entries, "\n") * "\n"
end

function cached_library(lib_path::String, key_path::String, key::String)
    return isfile(lib_path) && isfile(key_path) && read(key_path, String) == key
end

function build_libnormaliz_julia(builddir::String, srcdir::String, key::String)
    @info "Compiling libnormaliz_julia"

    jlcxx_cmake_dir = joinpath(CxxWrap.prefix_path(), "lib", "cmake", "JlCxx")
    julia_exec = joinpath(Sys.BINDIR, Base.julia_exename())
    coverage = cxx_coverage_enabled()

    rm(builddir; force=true, recursive=true)

    cmake = CMake_jll.cmake()
    withenv("JULIA_LOAD_PATH" => nothing) do
        run(`$cmake
            -DJulia_EXECUTABLE=$julia_exec
            -DJlCxx_DIR=$jlcxx_cmake_dir
            -DCMAKE_BUILD_TYPE=$(coverage ? "Debug" : "Release")
            -DNORMALIZ_JULIA_ENABLE_COVERAGE=$(coverage ? "ON" : "OFF")
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
            -Dlibomp_path=$(libomp_path())
            -B $builddir
            -S $srcdir
        `)

        run(`$cmake
            --build $builddir
            --config $(coverage ? "Debug" : "Release")
            --
            -j$(max(1, div(Sys.CPU_THREADS, 2)))
        `)
    end

    key_path = joinpath(builddir, "lib", "libnormaliz_julia.buildinfo")
    write(key_path, key)
end

function locate_libnormaliz_julia()
    depsdir = abspath(joinpath(@__DIR__, "..", "deps"))
    srcdir = joinpath(depsdir, "src")
    builddir = joinpath(depsdir, "build-$VERSION")
    lib_path = joinpath(builddir, "lib", "libnormaliz_julia.$(Libdl.dlext)")
    key_path = joinpath(builddir, "lib", "libnormaliz_julia.buildinfo")
    key = build_key(srcdir)

    cached_library(lib_path, key_path, key) && return lib_path

    build_libnormaliz_julia(builddir, srcdir, key)

    return lib_path
end

end
