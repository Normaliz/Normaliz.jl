project(Normaliz)

cmake_minimum_required(VERSION 3.01)

find_package(JlCxx REQUIRED)

include_directories(${JlCxx_DIR}/../../../include/)

SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${normaliz_include} -std=c++14" )
SET( CMAKE_SHARED_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} ${normaliz_lib} -lnormaliz" )

add_library(normaliz SHARED normaliz.cpp)
target_link_libraries(normaliz JlCxx::cxxwrap_julia "-lnormaliz")

install(TARGETS
  normaliz
ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
