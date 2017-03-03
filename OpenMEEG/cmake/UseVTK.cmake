#------------------------------------------------------------
# VTK library
#------------------------------------------------------------

if (USE_VTK)
    find_package(VTK COMPONENTS vtkIOXML vtkIOLegacy NO_MODULE)
    if (VTK_FOUND)
        if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
            add_compile_options(-Wno-inconsistent-missing-override)
        endif()
        set(OPENMEEG_OTHER_LIBRARY_DIRECTORIES ${VTK_LIBRARY_DIRS} ${OPENMEEG_OTHER_LIBRARY_DIRECTORIES})
        set(OPENMEEG_OTHER_INCLUDE_DIRECTORIES ${OPENMEEG_OTHER_INCLUDE_DIRECTORIES} ${VTK_INCLUDE_DIRS})
        set(OPENMEEG_LIBRARIES ${OPENMEEG_LIBRARIES} ${VTK_LIBRARIES})
    else()
        message(FATAL_ERROR "Please set VTK_DIR")
    endif()
endif()
