#!/bin/bash



declare -A _COLOR=(
  [bold_red]="\033[31;1m"
  [bold_green]="\033[32;1m"
  [yellow]="\033[0;33m"
  [reset]="\033[0;m"
)

function error() {
  echo -e "${_COLOR[bold_red]}ERROR: $*${_COLOR[reset]}" >&2
  exit 1
}

function warning() {
  echo -e "${_COLOR[yellow]}WARNING: $*${_COLOR[reset]}" >&2
}

function notice() {
  echo -e "${_COLOR[bold_green]}$*${_COLOR[reset]}"
}
