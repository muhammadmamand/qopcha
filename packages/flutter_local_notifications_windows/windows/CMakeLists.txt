# Stub native library — avoids ATL (atlbase.h) requirement on Windows.
cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "flutter_local_notifications_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

add_library(${PROJECT_NAME} SHARED
  "empty_stub.cpp"
)

set_target_properties(${PROJECT_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
)

target_compile_definitions(${PROJECT_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

set(flutter_local_notifications_windows_bundled_libraries
  $<TARGET_FILE:${PROJECT_NAME}>
  PARENT_SCOPE
)
