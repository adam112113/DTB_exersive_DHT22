cmake_minimum_required(VERSION 3.10)
project(SensorMonitoring)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find SQLite3
find_package(SQLite3 REQUIRED)

# Find threads library
find_package(Threads REQUIRED)

# Include directories
include_directories(${SQLite3_INCLUDE_DIRS})

# Add executable
add_executable(sensor_monitor sensor_monitor.cpp)

# Link libraries
target_link_libraries(sensor_monitor 
    ${SQLite3_LIBRARIES}
    wiringPi
    Threads::Threads
)

# Installation
install(TARGETS sensor_monitor DESTINATION /usr/local/bin)

# Print build information
message(STATUS "Building Sensor Monitoring System")
message(STATUS "SQLite3 found: ${SQLite3_FOUND}")
message(STATUS "SQLite3 include: ${SQLite3_INCLUDE_DIRS}")
message(STATUS "SQLite3 libraries: ${SQLite3_LIBRARIES}")
