cmake_minimum_required(VERSION 3.5)

project(libnormaliz_julia)

set(JL_TARGET normaliz_julia)

set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

find_package(JlCxx REQUIRED)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
message(STATUS "Found JlCxx at ${JlCxx_location}")

include(CheckCXXCompilerFlag)

set(CMAKE_CXX_STANDARD 14)

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

include_directories(
    ${gmp_prefix}/include
    ${normaliz_prefix}/include
    ${mpfr_prefix}/include
    ${nauty_prefix}/include
    ${flint_prefix}/include
    )

add_library(${JL_TARGET} SHARED normaliz.cpp)

target_link_libraries(${JL_TARGET}
    JlCxx::cxxwrap_julia
    JlCxx::cxxwrap_julia_stl
    ${libnormaliz_path}
    ${libflint_path}
    ${libmpfr_path}
    ${libnauty_path}
    ${libgmp_path}
    ${libgmpxx_path}
    ${libomp_path}
    )

install(TARGETS
  ${JL_TARGET}
LIBRARY DESTINATION lib
ARCHIVE DESTINATION lib
RUNTIME DESTINATION lib)
