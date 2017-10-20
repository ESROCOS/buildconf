INCLUDE(FindPkgConfig)

function(esrocos_init)  

endfunction(esrocos_init)

function(esrocos_add_dependency REQ_MODULE)
  
  set(ENV{PKG_CONFIG_PATH} "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig/")
 
  pkg_check_modules(LINK_LIBS REQUIRED ${REQ_MODULE})

endfunction(esrocos_add_dependency)

function(esrocos_install_dependency_info)

  set(WRITE_OUT "libs:")

  foreach(LIB ${LINK_LIBS_STATIC_LIBRARIES})
  
    set(NOT_INCLUDED TRUE)
    foreach(DIR ${LINK_LIBS_STATIC_LIBRARY_DIRS})
      if(EXISTS "${DIR}/lib${LIB}.a") 
        set(WRITE_OUT "${WRITE_OUT}\n- ${DIR}/lib${LIB}.a")
        set(NOT_INCLUDED FALSE)
      elseif(EXISTS "${DIR}/lib${LIB}.so") 
        set(WRITE_OUT "${WRITE_OUT}\n- ${DIR}/lib${LIB}.so")
        set(NOT_INCLUDED FALSE)
      endif()
    endforeach(DIR)

    if(${NOT_INCLUDED})
      find_library(FOUND ${LIB})
      if(EXISTS ${FOUND})
        set(WRITE_OUT "${WRITE_OUT}\n- ${FOUND}")
      endif()
      unset (FOUND CACHE)
    endif()

  endforeach(LIB)

  #message(${LINK_LIBS_STATIC_LIBRARIES})

  file(WRITE ${CMAKE_BINARY_DIR}/linkings.yml ${WRITE_OUT})

  install(FILES ${CMAKE_BINARY_DIR}/linkings.yml
  DESTINATION ${CMAKE_SOURCE_DIR}/)

endfunction(esrocos_install_dependency_info)	
