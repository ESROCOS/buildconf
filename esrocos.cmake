# Additional CMake modules for ESROCOS 
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake_modules")

# PkgConfig
INCLUDE(FindPkgConfig)
set(ENV{PKG_CONFIG_PATH} "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig/")
set(WRITE_OUT "libs:")
  
function(esrocos_add_dependency REQ_MODULE)
  
  pkg_check_modules(LINK_LIBS REQUIRED ${REQ_MODULE})

  set(LOCAL_WO "")

  foreach(LIB ${LINK_LIBS_STATIC_LIBRARIES})
   
    set(NOT_INCLUDED TRUE)
    foreach(DIR ${LINK_LIBS_STATIC_LIBRARY_DIRS})
      if(EXISTS "${DIR}/lib${LIB}.a") 
        set(LOCAL_WO "${LOCAL_WO}\n- ${DIR}/lib${LIB}.a")
        set(NOT_INCLUDED FALSE)
      elseif(EXISTS "${DIR}/lib${LIB}.so") 
        set(LOCAL_WO "${LOCAL_WO}\n- ${DIR}/lib${LIB}.so")
        set(NOT_INCLUDED FALSE)
      endif()

      
    endforeach(DIR)

    if(${NOT_INCLUDED})
      find_library(FOUND ${LIB})
      if(EXISTS ${FOUND})
        set(LOCAL_WO "${LOCAL_WO}\n- ${FOUND}" )
      endif()
      unset (FOUND CACHE)
    endif()

  endforeach(LIB)

  set(WRITE_OUT "${WRITE_OUT}\n${LOCAL_WO}" PARENT_SCOPE)

endfunction(esrocos_add_dependency)


function(esrocos_install_dependency_info)

  message(${WRITE_OUT})

  file(WRITE ${CMAKE_BINARY_DIR}/linkings.yml ${WRITE_OUT})

  install(FILES ${CMAKE_BINARY_DIR}/linkings.yml
  DESTINATION ${CMAKE_SOURCE_DIR}/)

endfunction(esrocos_install_dependency_info)	

# CMake function to build an ASN.1 types package in ESROCOS
#
# Syntax:
#       esrocos_asn1_types_package(<name>
#           [[ASN1] <file.asn> ...]
#           [OUTDIR <dir>]
#           [IMPORT <pkg> ...])
#
# Where <name> is the name of the created package, <file.asn> are the 
# ASN.1 type files that compose the package, and <pkg> are the names 
# of existing ASN.1 type packages on which <name> depends. The names 
# are relative to the ESROCOS install directory (e.g., types/base).
# <dir> is the directory where the C files compiled from ASN.1 are 
# written, relative to ${CMAKE_CURRENT_BINARY_DIR} (by default, <name>).
#
# Creates the following targets:
#  - <name>_timestamp: command to compile the ASN.1 files to C creating
#    a timestamp file.
#  - <name>_generate_c: compile the ASN.1 files, checking the timestamp
#    file to recompile only when the input files are changed.
#
# Creates the following variables:
#  - <name>_ASN1_SOURCES: ASN.1 files to install
#  - <name>_ASN1_LIB_SOURCES: C source files with encoder/decoder 
#    functions generated by the ASN.1 compiler.

### TO-DO ###
#  - <name>_ASN1_LIB_COMMON_SOURCES: C source files with basic functions
#    that are always generated by the ASN.1 compiler.
#  - <name>_ASN1_TEST_SOURCES: C source files generated by the ASN.1 
#    compiler for unit testing (including the tested encoder/decoder 
#    functions).
#


# In order to generate the lists of C files, a first compilation of the
# ASN.1 input files is performed at the CMake configuration stage.
#           
function(esrocos_asn1_types_package NAME)

    # Process optional arguments
    set(MODE "ASN1")
    set(ASN1_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/${NAME}")
    foreach(ARG ${ARGN})
        if(ARG STREQUAL "ASN1")
            # Set next argument mode to ASN1 file
            set(MODE "ASN1")
        elseif(ARG STREQUAL "IMPORT")
            # Set next argument mode to IMPORT package
            set(MODE "IMPORT")
        elseif(ARG STREQUAL "OUTDIR")
            # Set next argument mode to output directory
            set(MODE "OUTDIR")
        else()
            # File or package name
            if(MODE STREQUAL "ASN1")
                # Add file (path relative to CMAKE_CURRENT_SOURCE_DIR)
                list(APPEND ASN1_LOCAL "${CMAKE_CURRENT_SOURCE_DIR}/${ARG}")
            elseif(MODE STREQUAL "IMPORT")
                # Add imported package
                list(APPEND IMPORTS ${ARG})
            elseif(MODE STREQUAL "OUTDIR")
                # Add imported package
                set(ASN1_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/${ARG}")
            else()
                # Unexpected mode
                message(FATAL_ERROR "Internal error at esrocos_asn1_types_package(${NAME}): wrong mode ${MODE}.")
            endif()
        endif()
    endforeach()

    # Read the .asn files from the imported packages, assumed to be at
    # ${CMAKE_INSTALL_PREFIX}/types/${PKG}
    foreach(PKG ${IMPORTS})
        file(GLOB NEW_IMPORTS "${CMAKE_INSTALL_PREFIX}/${PKG}/*.asn")
        list(APPEND ASN1_IMPORTS ${NEW_IMPORTS})
    endforeach()
        
    # List of .asn files to be compiled: local + imported
    list(APPEND ASN1_FILES ${ASN1_LOCAL} ${ASN1_IMPORTS})

    # Directory to write the output of the ASN.1 compiler (C files)
    file(MAKE_DIRECTORY ${ASN1_OUT_DIR})

    # Timestamp file
    set(${NAME}_timestamp ${CMAKE_CURRENT_BINARY_DIR}/timestamp)

    # First compilation, needed to build the lists of C files
    if(NOT EXISTS ${NAME}_timestamp)
        execute_process(
            COMMAND asn1.exe -c -typePrefix asn1Scc -uPER -wordSize 8 -ACN -o ${ASN1_OUT_DIR} -atc ${ASN1_FILES}
            RESULT_VARIABLE ASN1SCC_RESULT
        )

        if(${ASN1SCC_RESULT} EQUAL 0)
            execute_process(
                COMMAND ${CMAKE_COMMAND} -E touch ${NAME}_timestamp
            )
            message(STATUS "ASN.1 first compilation successful.")
        else()
            message(FATAL_ERROR "ASN.1 first compilation failed.")
        endif()
    endif()


    # Command for C compilation; creates timestamp file
    add_custom_command(OUTPUT ${NAME}_timestamp
        COMMAND asn1.exe -c -typePrefix asn1Scc -uPER -wordSize 8 -ACN -o ${ASN1_OUT_DIR} -atc ${ASN1_FILES}
        COMMAND ${CMAKE_COMMAND} -E touch ${NAME}_timestamp
        DEPENDS ${ASN1_FILES}
        COMMENT "Generate header files for: ${ASN1_IMPORTS} ${ASN1_FILES} in ${ASN1_OUT_DIR}"
    )

    # Target for C compilation; uses stamp file to run dependent targets only if changed
    add_custom_target(
        ${NAME}
        DEPENDS ${NAME}_timestamp
    )

    # Get generated .c files 
    file(GLOB C_FILES "${ASN1_OUT_DIR}/*.c")


    # Export variables
    set(${NAME}_ASN1_SOURCES ${ASN1_LOCAL} PARENT_SCOPE)
    set(${NAME}_ASN1_TEST_SOURCES ${C_FILES} PARENT_SCOPE)

endfunction(esrocos_asn1_types_package)


# CMake function to create an executable for the encoder/decoder unit
# tests generated by the ASN.1 compiler.
#
# Syntax:
#       esrocos_asn1_types_test(<name>)
#
# Where <name> is the name of an ASN.1 types package created with the 
# function esrocos_asn1_types_package.
#   
function(esrocos_asn1_types_build_test NAME)
    
    if(DEFINED ${NAME}_ASN1_TEST_SOURCES)
        # Unit tests executable
        add_executable(${NAME}_test ${${NAME}_ASN1_TEST_SOURCES})
        add_dependencies(${NAME}_test ${NAME}_generate_c)
    else()
        message(FATAL_ERROR "esrocos_asn1_types_test(${NAME}): ${NAME}_ASN1_TEST_SOURCES not defined. Was esrocos_asn1_types_package called?")
    endif()
    
endfunction(esrocos_asn1_types_build_test)


# CMake function to install the ASN.1 type files into the ESROCOS 
# install directory.
#
# Syntax:
#       esrocos_asn1_types_install(<name> [<prefix>])
#
# Where <name> is the name of an ASN.1 types package created with the 
# function esrocos_asn1_types_package, and <prefix> is the install
# directory (by default, ${CMAKE_INSTALL_PREFIX}/types/<name>).
#   
function(esrocos_asn1_types_install NAME)

    # Set prefix: 2nd argument or default
    if(ARGC EQUAL 1)
        set(PREFIX "${CMAKE_INSTALL_PREFIX}/types/${NAME}")
    elseif(ARGC EQUAL 2)
        set(PREFIX "${ARGV1}")
    else()
        message(FATAL_ERROR "Wrong number of arguments at esrocos_asn1_types_install(${NAME})")
    endif()
    
    if(DEFINED ${NAME}_ASN1_SOURCES)
        # Install ASN.1 files
        install(FILES ${${NAME}_ASN1_SOURCES} DESTINATION ${PREFIX})
    else()
        message(FATAL_ERROR "esrocos_asn1_types_install(${NAME}): ${NAME}_ASN1_SOURCES not defined. Was esrocos_asn1_types_package called?")
    endif()
    
endfunction(esrocos_asn1_types_install)


# CMake function to create a target dependency on a library to be 
# located with pkg-config. It tries to find the library, and applies 
# the library's include and link options to the target.
#
# Syntax:
#       esrocos_pkgconfig_dependency(<target> [<pkgconfig_dep_1> <pkgconfig_dep_2>...])
#
# Where <target> is the name of the CMake library or executable target, 
# and <pkgconfig_dep_N> are the pkg-config packages on which it depends.
#   
function(esrocos_pkgconfig_dependency TAR)
    foreach(PKG ${ARGN})
        pkg_search_module(${PKG} REQUIRED ${PKG})
        if(${PKG}_FOUND)
            target_link_libraries(${TAR} PUBLIC ${${PKG}_LIBRARIES})
            target_include_directories(${TAR} PUBLIC ${${PKG}_INCLUDE_DIRS})
            target_compile_options(${TAR} PUBLIC ${${PKG}_CFLAGS_OTHER})
        else()
            message(SEND_ERROR "Cannot find pkg-config package ${PKG} required by ${TAR}.")
        endif()
    endforeach()
endfunction(esrocos_pkgconfig_dependency)

