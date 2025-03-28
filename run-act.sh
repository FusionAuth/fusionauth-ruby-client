#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

EVENT="workflow_dispatch"
INPUTS=""
PARSED_INPUTS=()
PROFILE=""
VERBOSE=false
WORKFLOW=""

# Script metadata. Don't modify this.
MYDIR=$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P)
cd "${MYDIR}"
MYNAME=$(basename "$0")

# Configure colorful messages.
GRAY=$(tput setaf 248)
GREEN=$(tput setaf 2)
RED=$(tput setaf 202)
RESET=$(tput sgr0)

# Output formatting.
function success() { echo -e "${GREEN}${1}${RESET}"; }
function info()    { echo -e "${GRAY}${1}${RESET}"; }
function error()   { echo -e "${RED}ERROR: ${1}${RESET}" >&2; }
function fail()    { echo -e "\n${RED}ERROR: ${1}${RESET}" >&2; exit 1; }
function argerr()  { echo -e "\n${RED}ERROR: ${1}${RESET}" >&2; show_help; }

# Helper functions.
function file_missing() { if [[ -f "${1}" ]]; then return 1; else return 0; fi }

function show_help() {
  echo -e "\nUsage: ${MYNAME} --workflow [workflow-name.yaml] --profile [aws-profile-name]\n"
  echo -e "    Flags            Description                     Req    Default"
  echo -e "    -------------    ----------------------------    ---    -------------------"
  echo -e "    -e --event       Github event to simulate               workflow_dispatch"
  echo -e "    -i --inputs      CSV list of k/v pairs            *     ${GRAY}null${RESET}"
  echo -e "    -p --profile     AWS profile to use for auth      Y     ${GRAY}null${RESET}"
  echo -e "    -v --verbose     Enable verbose mode (set -xv)          ${GRAY}disabled${RESET}"
  echo -e "    -w --workflow    Path/file of workflow to run     Y     ${GRAY}null${RESET}"
  echo -e "    -h --help        Show this message\n"
  echo -e "    * --inputs requirements are determined by the workflow.\n"
  echo -e "See https://nektosact.com/ for more info about 'act'.\n"
  exit
}


function parse_args() {
  # Parse the args.
  while [[ $# -gt 0 ]]; do
    case $1 in
      -e|--event) shift
        if (( $# < 1 )); then argerr "--event requires an event type [push|pull_request|workflow_dispatch]"
        else EVENT="${1}"; fi
        shift;;
      -i|--inputs) shift
        if (( $# < 1 )); then argerr "--inputs requires a csv list of input args"
        else INPUTS="${1}"; fi
        shift;;
      -p|--profile) shift
        if (( $# < 1 )); then argerr "--profile requires an AWS profile name"
        else PROFILE="${1}"; fi
        shift;;
      -w|--workflow) shift
        if (( $# < 1 )); then argerr "--workflow requires a path to a workflow file"
        else WORKFLOW="${1}"; fi
        shift;;
      -v|--verbose) VERBOSE=true; shift;;
      -h|--help) show_help;;
      *) argerr "Unknown argument '$1'";;
    esac
  done

  # Enable verbose mode if requested.
  if [ "${VERBOSE}" = true ]; then set -xv; fi

  # Make sure --workflow is passed.
  if [[ -z "${WORKFLOW}" ]]; then argerr "--workflow is required"; fi
  # Make sure --workflow is passed.
  if [[ -z "${PROFILE}" ]]; then argerr "--profile is required"; fi
  # Make sure workflow file exists
  if file_missing "${WORKFLOW}"; then fail "Workflow '${WORKFLOW}' does not exist"; fi
}


function validate_prereqs() {
  local prereqs="act gh"
  for p in ${prereqs}; do
    if ! command -v "${p}" &>/dev/null; then
      error "${p} not found. Install it and try again."
      if [[ "${p}" == "gh" ]]; then
        info "\nAfter installing gh, login:"
        info "    gh auth login"
        info "\nMake sure you can get a token:"
        info "    gh auth token"
      fi
      exit 1
    fi
  done
}


function parse_inputs() {
  if [[ -n "${INPUTS}" ]]; then
    IFS=","
    for i in ${INPUTS}; do
      PARSED_INPUTS+=(--input "${i}")
    done
  fi
}


function main() {
  parse_args "$@"
  validate_prereqs
  parse_inputs

  act "${EVENT}" \
    --secret GITHUB_TOKEN="$(gh auth token)" \
    --secret-file .env \
    --workflows "${WORKFLOW}" \
    --env-file <(aws configure export-credentials --profile "${PROFILE}" --format env) \
    "${PARSED_INPUTS[@]}"
}


main "$@"
