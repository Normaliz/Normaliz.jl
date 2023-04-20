project(libormaliz_julia)

cmake_minimum_required(VERSION 3.01)
set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

find_package(JlCxx REQUIRED)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)

message(STATUS "Found JlCxx at ${JlCxx_location}")

include(CheckCXXCompilerFlag)

set(CMAKE_CXX_STANDARD 14)

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${normaliz_include}" )
SET( CMAKE_SHARED_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} ${normaliz_lib}" )

add_library(normaliz_julia SHARED normaliz.cpp)

target_link_libraries(normaliz_julia
    JlCxx::cxxwrap_julia
    JlCxx::cxxwrap_julia_stl
    "-lnormaliz"
    "-leanticxx"
    "-leantic"
    "-lantic"
    "-larb"
    "-lflint"
    "-lgmp"
    )

install(TARGETS
  normaliz_julia
LIBRARY DESTINATION lib
ARCHIVE DESTINATION lib
RUNTIME DESTINATION lib)
