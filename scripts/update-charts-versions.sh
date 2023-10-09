#!/usr/bin/env bash
#
# This script updates the Helm charts versions to use
# whenever there's a new release in the upstream charts
# or there's a version bump in the charts we maintain.
#
# This script is used on the "Update charts" GH action that is
# triggered periodically and creates a PR if new versions are
# detected.

set -o errexit
set -o pipefail

# Constants
RESET='\033[0m'
GREEN='\033[38;5;2m'
RED='\033[38;5;1m'
YELLOW='\033[38;5;3m'

# Axiliar functions
log() {
    printf "%b\n" "${*}" >&2
}
export -f log

print_menu() {
    local script
    script=$(basename "${BASH_SOURCE[0]}")
    log "${RED}NAME${RESET}"
    log "    $(basename -s .sh "${BASH_SOURCE[0]}")"
    log ""
    log "${RED}SYNOPSIS${RESET}"
    log "    $script [${YELLOW}-h${RESET}] [${YELLOW}-t ${GREEN}\"target\"${RESET}]"
    log ""
    log "${RED}DESCRIPTION${RESET}"
    log "    Script to update charts versions."
    log ""
    log "    The options are as follow:"
    log ""
    log "      ${YELLOW}-t, --target ${GREEN}[target]${RESET}                           Target to use (staging or production)."
    log ""
    log "${RED}EXAMPLES${RESET}"
    log "      $script --help"
    log "      $script --target \"staging\""
    log "      $script --target \"production\""
    log ""
}

target="staging"
help_menu=0
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help)
            help_menu=1
            ;;
        -t|--target)
            shift; target="${1:?missing target}"
            ;;
        *)
            log "Invalid command line flag $1" >&2
            exit 1
            ;;
    esac
    shift
done

if [[ "$target" != "production" ]] && [[ "$target" != "staging" ]]; then
    log "Allowed targets are: \"production\" and \"staging\". Found: $target"
    help_menu=1
fi

if [[ "$help_menu" -eq 1 ]]; then
    print_menu
    exit 0
fi

tmp_dir="$(mktemp -d)"
export tmp_dir
trap 'rm -rf "$tmp_dir"' EXIT

update_chart_version() {
  local app_file="${1:?app_file is required}"
  chart="$(basename "$app_file" .yaml)"
  chart="${chart%"-app"}"

  if yq '(.spec.sources[] | has("chart"))' "$app_file" | grep -q true; then
      log "Updating chart version for $chart"
      repoURL=$(yq '(.spec.sources[] | select(has("chart"))) | .repoURL' "$app_file")
      helm pull "oci://${repoURL}/${chart}" --untar --destination "$tmp_dir" > /dev/null 2>&1
      version=$(yq .version "${tmp_dir}/${chart}/Chart.yaml")
      yq "(.spec.sources[] | select(.repoURL == \"$repoURL\") | .targetRevision) = \"$version\"" -i "$app_file"
  fi
}
export -f update_chart_version

find "infrastructure/manifests/${target}/argo-cd/argo-cd/apps" -name '*.yaml' -print0 | xargs -0 -I {} bash -c 'update_chart_version "$@"' _ {}
