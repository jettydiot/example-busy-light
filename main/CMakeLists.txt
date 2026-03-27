idf_component_register(
    SRCS "main.c" "driver_registry.c"
    INCLUDE_DIRS "."
    REQUIRES jettyd
)
set(DEVICE_YAML "${CMAKE_CURRENT_SOURCE_DIR}/../device.yaml")
set(DRIVER_REG_C "${CMAKE_CURRENT_SOURCE_DIR}/driver_registry.c")
set(BUILD_PY "${CMAKE_CURRENT_SOURCE_DIR}/../build.py")
if(EXISTS "${DEVICE_YAML}" AND EXISTS "${BUILD_PY}")
    execute_process(
        COMMAND python3 ${BUILD_PY} ${DEVICE_YAML} ${DRIVER_REG_C}
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/.."
        RESULT_VARIABLE CODEGEN_RESULT
    )
endif()
