
# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.18.1)

# Declares and names the project.

project("openworkouttrackerbackend")

# SQLite

find_package (SQLite3)
include_directories(${SQLite3_INCLUDE_DIRS})
include_directories("/opt/homebrew/Cellar/sqlite//3.39.2/include") # Filthy hack

# libxml2

include_directories("/opt/homebrew/Cellar/libxml2/2.9.14_3/include") # Filthy hack
include_directories("/opt/homebrew/Cellar/libxml2/2.9.14_3/include/libxml2") # Filthy hack

# Creates and names a library, sets it as either STATIC
# or SHARED, and provides the relative paths to its source code.
# You can define multiple libraries, and CMake builds them for you.
# Gradle automatically packages shared libraries with your APK.

file (GLOB_RECURSE Backend_SOURCES CONFIGURE_DEPENDS "*.cpp")
file (GLOB_RECURSE Backend_HEADERS CONFIGURE_DEPENDS "*.h")

include_directories("../Activities/")
include_directories("../Bike/")
include_directories("../Common/")
include_directories("../Data/")
include_directories("../FileLib/")
include_directories("../PeakFinder/cpp")
include_directories("../LibMath/cpp")
include_directories("../Sensors/")
include_directories("../Shoes/")
include_directories("../Units/")
include_directories("../User/")

add_library( # Sets the name of the library.
             openworkouttrackerbackend
             # Sets the library as a shared library.
             SHARED
             # Provides a relative path to your source file(s).
             Activity.cpp
             ActivityFactory.cpp
             ActivityMgr.mm
             BenchPress.cpp
             BenchPressAnalyzer.cpp
             BikePlanGenerator.cpp
             ChinUp.cpp
             ChinUpAnalyzer.cpp
             Cycling.cpp
             FtpCalculator.cpp
             GForceAnalyzer.cpp
             GForceAnalyzerFactory.cpp
             Hike.cpp
             IntensityCalculator.cpp
             LiftingActivity.cpp
             MountainBiking.cpp
             MovingActivity.cpp
             OpenWaterSwim.cpp
             PlanGenerator.cpp
             PoolSwim.cpp
             PushUp.cpp
             PushUpAnalyzer.cpp
             PullUp.cpp
             PullUpAnalyzer.cpp
             Run.cpp
             RunPlanGenerator.cpp
             Squat.cpp
             SquatAnalyzer.cpp
             StationaryCycling.cpp
             Swim.cpp
             SwimPlanGenerator.cpp
             TrainingPaceCalculator.cpp
             Treadmill.cpp
             Triathlon.cpp
             UnitMgr.cpp
             VO2MaxCalculator.cpp
             Walk.cpp
             Workout.cpp
             WorkoutFactory.cpp
             WorkoutPlanGenerator.cpp
             WorkoutScheduler.cpp
             ../Data/Database.cpp
             ../Data/DataExporter.cpp
             ../Data/DataImporter.cpp
             ../FileLib/CsvFileWriter.cpp
             ../FileLib/File.cpp
             ../FileLib/FitFileWriter.cpp
             ../FileLib/GpxFileReader.cpp
             ../FileLib/GpxFileWriter.cpp
             ../FileLib/KmlFileReader.cpp
             ../FileLib/TcxFileReader.cpp
             ../FileLib/TextFileReader.cpp
             ../FileLib/XmlFileReader.cpp
             ../FileLib/XmlFileWriter.cpp
             ../FileLib/ZwoFileReader.cpp
             ../FileLib/ZwoFileWriter.cpp
             ../Units/UnitConverter.cpp
             ../User/User.cpp)

# Searches for a specified prebuilt library and stores the path as a
# variable. Because CMake includes system libraries in the search path by
# default, you only need to specify the name of the public NDK library
# you want to add. CMake verifies that the library exists before
# completing its build.

find_library( # Sets the name of the path variable.
              log-lib
              # Specifies the name of the NDK library that you want CMake to locate.
              log )

# Specifies libraries CMake should link to your target library. You
# can link multiple libraries, such as libraries you define in this
# build script, prebuilt third-party libraries, or system libraries.

target_link_libraries( # Specifies the target library.
                       openworkouttrackerbackend
                       # Links the target library to the log library included in the NDK.
                       ${log-lib} )
