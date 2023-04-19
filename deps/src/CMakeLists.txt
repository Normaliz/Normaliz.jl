project(libormaliz_julia)

cmake_minimum_required(VERSION 3.01)

find_package(JlCxx REQUIRED)
message(STATUS "Found JlCxx at ${JlCxx_location}")

include_directories(${JlCxx_DIR}/../../../include/)

SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${normaliz_include} -std=c++14" )
SET( CMAKE_SHARED_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} ${normaliz_lib} -lnormaliz -leanticxx -leantic -lantic -larb -lflint -lgmp " )

add_library(normaliz_julia SHARED normaliz.cpp)

target_link_libraries(normaliz_julia
    JlCxx::cxxwrap_julia
    JlCxx::cxxwrap_julia_stl
    "-lnormaliz"
    )

install(TARGETS
  normaliz_julia
ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
