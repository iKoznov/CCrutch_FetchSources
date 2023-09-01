include_guard()

# inspired from https://www.youtube.com/watch?v=mrSwJBJ-0z8&t=3633s
# TODO: Maybe use this: https://github.com/cpm-cmake/CPM.cmake
include(FetchContent)

# Maybe
# set(FETCHCONTENT_UPDATES_DISCONNECTED ON)
# https://gitlab.kitware.com/cmake/cmake/-/issues/19899

#[[
	TODO: maybe use cmake's dependency provider and cmake_language command
	https://cmake.org/cmake/help/latest/command/cmake_language.html#provider-examples
]]

set(CCRUTCH_EXTERNAL_DIR "${CMAKE_SOURCE_DIR}/external" CACHE PATH "")

if(DEFINED ENV{CI_JOB_TOKEN})
    # if fails, disable GitLab project setting:
    # Settings -> CI/CD -> Token Access -> Limit access to this project
    set(CCRUTCH_GIT_URL_BASE "https://gitlab-ci-token:$ENV{CI_JOB_TOKEN}@gitlab.com/" CACHE STRING "")
elseif(DEFINED ENV{GITHUB_TOKEN})
    set(CCRUTCH_GIT_URL_BASE "https://$ENV{GITHUB_TOKEN}@github.com/" CACHE STRING "")
    #set(GIT_URL_BASE "https://x-access-token:$ENV{GITHUB_TOKEN}@github.com/iKoznov-GitLab-Mirror")
else()
    set(CCRUTCH_GIT_URL_BASE "git@gitlab.com:" CACHE STRING "")
endif()


function(ccrutch_fetch_sources name)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "" "REQUIRED_FILE;GIT_REPO_NAME;GIT_TAG" "")

    if(EXISTS "${CCRUTCH_EXTERNAL_DIR}/${name}/${ARG_REQUIRED_FILE}")
        return()
    endif()

    FetchContent_Declare(${name}
        SOURCE_DIR "${CCRUTCH_EXTERNAL_DIR}/${name}"
        GIT_REPOSITORY "${CCRUTCH_GIT_URL_BASE}${ARG_GIT_REPO_NAME}.git"
        GIT_TAG "${ARG_GIT_TAG}")
    FetchContent_GetProperties(${name})

    if(${name}_POPULATED)
        return()
    endif()

    file(REMOVE_RECURSE
        "${FETCHCONTENT_BASE_DIR}/${name}-src/"
        "${FETCHCONTENT_BASE_DIR}/${name}-build/"
        "${FETCHCONTENT_BASE_DIR}/${name}-subbuild/")
    FetchContent_Populate(${name})

    if(NOT EXISTS "${CCRUTCH_EXTERNAL_DIR}/${name}/${ARG_REQUIRED_FILE}")
        message(FATAL_ERROR "missing required file: ${CCRUTCH_EXTERNAL_DIR}/${name}/${ARG_REQUIRED_FILE}")
    endif()
endfunction()
