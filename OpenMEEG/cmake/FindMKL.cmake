# - Try to find the Intel Math Kernel Library
# Once done this will define
#
#  MKL_FOUND - system has MKL
#  MKL_ROOT_DIR - path to the MKL base directory
#  MKL_INCLUDE_DIR - the MKL include directory
#  MKL_LIBRARIES - MKL libraries
#  MKL_LIBRARY_DIR - MKL library dir (for dlls!)
#
# we use mkl_link_tool to get the library needed depending on variables
# There are few sets of libraries:
# Array indexes modes:
# LP - 32 bit indexes of arrays
# ILP - 64 bit indexes of arrays
# Threading:
# SEQUENTIAL - no threading
# INTEL - Intel threading library
# GNU - GNU threading library
# MPI support
# NOMPI - no MPI support
# INTEL - Intel MPI library
# OPEN - Open MPI library
# SGI - SGI MPT Library

set(CMAKE_FIND_DEBUG_MODE 1)

# unset this variable defined in matio
unset(MSVC)

set(MKL_POSSIBLE_LOCATIONS
    $ENV{MKLDIR}
    ${MKL_ROOT_DIR}
    /opt/intel/mkl
    /opt/intel/cmkl
    /Library/Frameworks/Intel_MKL.framework/Versions/Current/lib/universal
    "C:/Program Files (x86)/Intel/ComposerXE-2011/mkl"
    "C:/Program Files (x86)/Intel/Composer XE 2013/mkl"
    "C:/Program Files/Intel/MKL/*/"
    "C:/Program Files/Intel/ComposerXE-2011/mkl"
    "C:/Program Files/Intel/Composer XE 2013/mkl"
    "C:/Program Files (x86)/Intel/Composer XE 2015/mkl/"
    "C:/Program Files/Intel/Composer XE 2015/mkl/"
    "C:/Program Files (x86)/IntelSWTools/compilers_and_libraries/windows/mkl/"
)

execute_process(COMMAND ls -lR ${CMAKE_BINARY_DIR} OUTPUT_VARIABLE aa)
message("[[${CMAKE_BINARY_DIR}]]")
message("${aa}")

# get the MKL ROOT
find_path(MKL_ROOT_DIR NAMES include/mkl_cblas.h PATHS ${MKL_POSSIBLE_LOCATIONS})
# from symlinks to real paths
get_filename_component(MKL_ROOT_DIR ${MKL_ROOT_DIR} REALPATH)

if (NOT MKL_ROOT_DIR)
    if (MKL_FIND_REQUIRED)
        MESSAGE(FATAL_ERROR "Could not find MKL: please provide MKL_DIR or environment {MKLDIR}")
    else()
        unset(MKL_ROOT_DIR CACHE)
    endif()
else()
    set(MKL_INCLUDE_DIR ${MKL_ROOT_DIR}/include)

    # set arguments to call the MKL provided tool for linking
	set(MKL_LINK_TOOL ${MKL_ROOT_DIR}/tools/mkl_link_tool)

    if (WIN32)
        set(MKL_LINK_TOOL ${MKL_LINK_TOOL}.exe)
    endif()
    
    # check that the tools exists or quit
    if (NOT EXISTS "${MKL_LINK_TOOL}")
        message(FATAL_ERROR "cannot find MKL tool: ${MKL_LINK_TOOL}")
    endif()

    # first the libs
    set(MKL_LINK_TOOL_COMMAND ${MKL_LINK_TOOL} "-libs")

    # possible versions
    # <11.3|11.2|11.1|11.0|10.3|10.2|10.1|10.0|ParallelStudioXE2016|ParallelStudioXE2015|ComposerXE2013SP1|ComposerXE2013|ComposerXE2011|CompilerPro>

    # not older than MKL 10 (2011)
    if (MKL_INCLUDE_DIR MATCHES "Composer.*2013")
        list(APPEND MKL_LINK_TOOL_COMMAND "--mkl=ComposerXE2013")
    elseif (MKL_INCLUDE_DIR MATCHES "Composer.*2011")
        list(APPEND MKL_LINK_TOOL_COMMAND "--mkl=ComposerXE2011")
    elseif (MKL_INCLUDE_DIR MATCHES "10.3")
        list(APPEND MKL_LINK_TOOL_COMMAND "--mkl=10.3")
    elseif(MKL_INCLUDE_DIR MATCHES "2013") # version 11 ...
        list(APPEND MKL_LINK_TOOL_COMMAND "--mkl=11.1")
    elseif(MKL_INCLUDE_DIR MATCHES "2015")
        list(APPEND MKL_LINK_TOOL_COMMAND "--mkl=11.2")
    elseif(MKL_INCLUDE_DIR MATCHES "2016")
        list(APPEND MKL_LINK_TOOL_COMMAND "--mkl=11.3")
    elseif(MKL_INCLUDE_DIR MATCHES "2017")
        list(APPEND MKL_LINK_TOOL_COMMAND "--mkl=11.3")
    elseif(MKL_INCLUDE_DIR MATCHES "2018")
        list(APPEND MKL_LINK_TOOL_COMMAND "--mkl=11.3")
    elseif (MKL_INCLUDE_DIR MATCHES "10")
        list(APPEND MKL_LINK_TOOL_COMMAND "--mkl=10.2")
    else()
        list(APPEND MKL_LINK_TOOL_COMMAND "--mkl=11.3")
    endif()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        list(APPEND MKL_LINK_TOOL_COMMAND "--compiler=clang")
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
        list(APPEND MKL_LINK_TOOL_COMMAND "--compiler=intel_c")
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        list(APPEND MKL_LINK_TOOL_COMMAND "--compiler=ms_c")
	else()
        list(APPEND MKL_LINK_TOOL_COMMAND "--compiler=gnu_c")
    endif()

    if (APPLE)
        list(APPEND MKL_LINK_TOOL_COMMAND "--os=mac")
    elseif(WIN32)
        list(APPEND MKL_LINK_TOOL_COMMAND "--os=win")
    else()
        list(APPEND MKL_LINK_TOOL_COMMAND "--os=lnx")
    endif()

	set(MKL_LIB_DIR)
    if (${CMAKE_SIZEOF_VOID_P} EQUAL 8 AND NOT FORCE_BUILD_32BITS)
        list(APPEND MKL_LINK_TOOL_COMMAND "--arch=intel64")
		set(MKL_LIB_DIR "intel64")
    else()
        list(APPEND MKL_LINK_TOOL_COMMAND "--arch=ia-32")
		set(MKL_LIB_DIR "ia32")
    endif()

    if (MKL_USE_sdl)
        list(APPEND MKL_LINK_TOOL_COMMAND "--linking=sdl")
    else()
        #  To simplify packaging. Otherwise we would have to copy the proper mkl files into the package.
        set(FORCE_STATIC_MKL True) # force to static linking for WIN32
        if (BUILD_SHARED_LIBS AND NOT FORCE_STATIC_MKL)
            list(APPEND MKL_LINK_TOOL_COMMAND "--linking=dynamic")
        else()
            list(APPEND MKL_LINK_TOOL_COMMAND "--linking=static")
        endif()
    endif()

    if (MKL_USE_parallel)
        list(APPEND MKL_LINK_TOOL_COMMAND "--parallel=yes")
    else()
        list(APPEND MKL_LINK_TOOL_COMMAND "--parallel=no")
    endif()

    if (FORCE_BUILD_32BITS)
        list(APPEND MKL_LINK_TOOL_COMMAND "--interface=cdecl")
        set(MKL_USE_interface "cdecl" CACHE STRING "disabled by FORCE_BUILD_32BITS" FORCE)
    else()
        list(APPEND MKL_LINK_TOOL_COMMAND "--interface=${MKL_USE_interface}")
    endif()

    if (MKL_USE_parallel)
        if (USE_OMP)
            list(APPEND MKL_LINK_TOOL_COMMAND "--openmp=gomp")
        else()
            list(APPEND MKL_LINK_TOOL_COMMAND "--threading-library=iomp5")
            list(APPEND MKL_LINK_TOOL_COMMAND "--openmp=iomp5")
        endif()
    endif()

    message("[[mkl_tool: ${MKL_LINK_TOOL_COMMAND}]]")
    execute_process(COMMAND ${MKL_LINK_TOOL_COMMAND}
                    OUTPUT_VARIABLE RESULT_LIBS
                    TIMEOUT 2
                    RESULT_VARIABLE COMMAND_WORKED
                    ERROR_QUIET)

    message("[[mkl_tool: ${COMMAND_WORKED}]]")

    set(MKL_LIBRARIES)

    if (NOT ${COMMAND_WORKED} EQUAL 0)
        message(FATAL_ERROR "Cannot find the MKL libraries correctly. Please check your MKL input variables and mkl_link_tool. The command executed was:\n ${MKL_LINK_TOOL_COMMAND}.")
    endif()

    set(MKL_LIBRARY_DIR)

    if (WIN32)
        set(MKL_LIBRARY_DIR "${MKL_ROOT_DIR}/lib/${MKL_LIB_DIR}/" "${MKL_ROOT_DIR}/../compiler/lib/${MKL_LIB_DIR}")

        # remove unwanted break
        string(REGEX REPLACE "\n" "" RESULT_LIBS ${RESULT_LIBS})

        # get the list of libs
        separate_arguments(RESULT_LIBS)
        foreach(i ${RESULT_LIBS})
            find_library(FULLPATH_LIB ${i} PATHS "${MKL_LIBRARY_DIR}")

            if (FULLPATH_LIB)
                list(APPEND MKL_LIBRARIES ${FULLPATH_LIB})
            elseif(i)
                list(APPEND MKL_LIBRARIES ${i})
            endif()
            unset(FULLPATH_LIB CACHE)
        endforeach()

    else() # UNIX and macOS
        # remove unwanted break
		string(REGEX REPLACE "\n" "" RESULT_LIBS ${RESULT_LIBS}) 
        if (MKL_LINK_TOOL_COMMAND MATCHES "static")
            string(REPLACE "$(MKLROOT)" "${MKL_ROOT_DIR}" MKL_LIBRARIES ${RESULT_LIBS})
            # hack for lin with libiomp5.a
            if (APPLE)
                string(REPLACE "-liomp5" "${MKL_ROOT_DIR}/../compiler/lib/libiomp5.a" MKL_LIBRARIES ${MKL_LIBRARIES})
            else()
                string(REPLACE "-liomp5" "${MKL_ROOT_DIR}/../compiler/lib/${MKL_LIB_DIR}/libiomp5.a" MKL_LIBRARIES ${MKL_LIBRARIES})
            endif()
            separate_arguments(MKL_LIBRARIES)

        else() # dynamic or sdl
            # get the lib dirs
            string(REGEX REPLACE "^.*-L[^/]+([^\ ]+).*" "${MKL_ROOT_DIR}\\1" INTEL_LIB_DIR ${RESULT_LIBS})
            if (NOT EXISTS ${INTEL_LIB_DIR})
                #   Work around a bug in mkl 2018
                set(INTEL_LIB_DIR1 "${INTEL_LIB_DIR}_lin")
                if (NOT EXISTS ${INTEL_LIB_DIR1})
                    message(FATAL_ERROR "MKL installation broken. Directory ${INTEL_LIB_DIR} does not exist.")
                endif()
                set(INTEL_LIB_DIR ${INTEL_LIB_DIR1})
            endif()
            set(MKL_LIBRARY_DIR ${INTEL_LIB_DIR} "${MKL_ROOT_DIR}/../compiler/lib/${MKL_LIB_DIR}")

            # get the list of libs
            separate_arguments(RESULT_LIBS)

            # set full path to libs
            foreach(i ${RESULT_LIBS})
                string(REGEX REPLACE " -" "-" i ${i})
                string(REGEX REPLACE "-l([^\ ]+)" "\\1" i ${i})
                string(REGEX REPLACE "-L.*" "" i ${i})

                find_library(FULLPATH_LIB ${i} PATHS "${MKL_LIBRARY_DIR}")

                if (FULLPATH_LIB)
                    list(APPEND MKL_LIBRARIES ${FULLPATH_LIB})
                elseif(i)
                    list(APPEND MKL_LIBRARIES ${i})
                endif()
                unset(FULLPATH_LIB CACHE)
            endforeach()
        endif()
    endif()

    # now definitions
    string(REPLACE "-libs" "-opts" MKL_LINK_TOOL_COMMAND "${MKL_LINK_TOOL_COMMAND}")
    execute_process(COMMAND ${MKL_LINK_TOOL_COMMAND} OUTPUT_VARIABLE RESULT_OPTS TIMEOUT 2 ERROR_QUIET)
    string(REGEX MATCHALL "[-/]D[^\ ]*" MKL_DEFINITIONS ${RESULT_OPTS})

    if (CMAKE_FIND_DEBUG_MODE)
        message("Exectuted command: \n${MKL_LINK_TOOL_COMMAND}")
        message("Found MKL_LIBRARIES:\n${MKL_LIBRARIES} ")
        message("Found MKL_DEFINITIONS:\n${MKL_DEFINITIONS} ")
        message("Found MKL_LIBRARY_DIR:\n${MKL_LIBRARY_DIR} ")
        message("Found MKL_INCLUDE_DIR:\n${MKL_INCLUDE_DIR} ")
    endif()

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(MKL DEFAULT_MSG MKL_INCLUDE_DIR MKL_LIBRARIES)

    mark_as_advanced(MKL_INCLUDE_DIR MKL_LIBRARIES MKL_DEFINITIONS MKL_ROOT_DIR)
endif()
