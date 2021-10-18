# CMakeList.txt : CMake project for RayIntersectionTest, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

project ("RayIntersectionTest")

# Add source to this project's executable.
add_executable (RayIntersectionTest "RayIntersectionTest.cpp" "RayIntersectionTest.h")

set_property(TARGET RayIntersectionTest PROPERTY VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")

# TODO: Add tests and install targets if needed.
