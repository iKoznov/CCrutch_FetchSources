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

function(ccrutch_get_git_url_base)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "GIT_REPO;OUTPUT_VARIABLE" "")

    if(DEFINED ${ARG_OUTPUT_VARIABLE})
        return()
    endif()

    find_package(Git REQUIRED)

    execute_process(
            COMMAND "${GIT_EXECUTABLE}" config
                --file "${ARG_GIT_REPO}/.git/config"
                --get remote.origin.url
            OUTPUT_STRIP_TRAILING_WHITESPACE
            OUTPUT_VARIABLE origin
            COMMAND_ERROR_IS_FATAL ANY
    )

    string(FIND "${origin}" "https://gitlab.com/" not_starts_with)
    if(NOT not_starts_with)
        if(DEFINED ENV{CI_JOB_TOKEN})
            # if fails, disable GitLab project setting:
            # Settings -> CI/CD -> Token Access -> Limit access to this project
            set(_git_url_base "https://gitlab-ci-token:$ENV{CI_JOB_TOKEN}@gitlab.com/")
        else()
            set(_git_url_base "https://gitlab.com/")
        endif()
    endif()

    string(FIND "${origin}" "git@gitlab.com:" not_starts_with)
    if(NOT not_starts_with)
        set(_git_url_base "git@gitlab.com:")
    endif()

    string(FIND "${origin}" "https://github.com/" not_starts_with)
    if(NOT not_starts_with)
        if(DEFINED ENV{GITHUB_TOKEN})
            set(_git_url_base "https://x-access-token:$ENV{GITHUB_TOKEN}@github.com/")
        else()
            set(_git_url_base "https://github.com/")
        endif()
    endif()

    string(FIND "${origin}" "git@github.com:" not_starts_with)
    if(NOT not_starts_with)
        set(_git_url_base "git@github.com:")
    endif()

    if(NOT _git_url_base)
        message(FATAL_ERROR "please provide git remote origin url")
    endif()

    set(${ARG_OUTPUT_VARIABLE} "${_git_url_base}" CACHE STRING "")
endfunction()


function(ccrutch_fetch_sources name)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "" "REQUIRED_FILE;GIT_REPO_NAME;GIT_TAG" "")
    set(CCRUTCH_EXTERNAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

    if(EXISTS "${CCRUTCH_EXTERNAL_DIR}/${name}/${ARG_REQUIRED_FILE}")
        message(VERBOSE "Fetching sources: ${name} - skipped")
        return()
    endif()

    ccrutch_get_git_url_base(
        GIT_REPO "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE _git_url_base
    )

    FetchContent_Declare(${name}
        SOURCE_DIR "${CCRUTCH_EXTERNAL_DIR}/${name}"
        GIT_REPOSITORY "${_git_url_base}${ARG_GIT_REPO_NAME}.git"
        GIT_TAG "${ARG_GIT_TAG}")
    FetchContent_GetProperties(${name})

    if(${name}_POPULATED)
        message(VERBOSE "Fetching sources: ${name} - populated")
    else()
        file(REMOVE_RECURSE
            "${FETCHCONTENT_BASE_DIR}/${name}-src/"
            "${FETCHCONTENT_BASE_DIR}/${name}-build/"
            "${FETCHCONTENT_BASE_DIR}/${name}-subbuild/")
        message(STATUS "Fetching sources: ${name} - downloading")
        FetchContent_Populate(${name})
    endif()

    if(NOT EXISTS "${CCRUTCH_EXTERNAL_DIR}/${name}/${ARG_REQUIRED_FILE}")
        message(FATAL_ERROR "missing required file: ${CCRUTCH_EXTERNAL_DIR}/${name}/${ARG_REQUIRED_FILE}")
    endif()
endfunction()
