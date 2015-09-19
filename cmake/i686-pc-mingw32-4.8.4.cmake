#
# To Cross-compile, use:
#  cmake -DCMAKE_TOOLCHAIN_FILE=../Toolchain-windows.cmake ..
#
# the name of the target operating system
SET(CMAKE_SYSTEM_NAME Windows)

# which compilers to use for C and C++
SET(CMAKE_C_COMPILER i686-pc-mingw32-gcc-4.8.4)
SET(CMAKE_CXX_COMPILER i686-pc-mingw32-g++-4.8.4)
SET(CMAKE_RC_COMPILER i686-pc-mingw32-windres)

# here is the target environment located
SET(CMAKE_FIND_ROOT_PATH /usr/i686-pc-mingw32)

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

