#!/bin/bash
#
# change google cloud projects more efficiently
# big thanks to https://github.com/junegunn/fzf

set -eo pipefail

if [[ ! $(fzf --version) ]]; then
  echo "fzf not installed, please install fzf"
  exit 1
fi

active_config=$(<$HOME/.config/gcloud/active_config)
current_project=$(awk -F " = " '/project/{print $2}' "$HOME/.config/gcloud/configurations/config_${active_config}")

cache=~/.cache/project-list

function help {
  cat << EOF
refresh : update project list cache
list : list projects in cache
current : current project
<projectname> : change project
EOF
}

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --border --height 20 --min-height 5 --layout reverse"
function match {
  target_project=$1
  target=$(grep -iPR "${target_project}" "${cache}")
  if [[ $(wc -l <<<"${target}") -gt 1 ]]; then
    sel=$(fzf --border --height 20 <<< "${target}" | awk '{print $NF}')
    gcloud config set project "${sel}"
    echo "--- ${sel} ---"
  else
    echo "--- $(awk '{print $NF}' <<< "${target}") ---"
    gcloud config set project "$(awk '{print $NF}' <<< "${target}")"
  fi
}

function blankmatch {
  sel=$(fzf < ~/.cache/project-list | awk '{print $NF}')
  gcloud config set project "${sel}"
  echo "--- ${sel} ---"
}

function refresh {
  echo "refreshing project list..."; gcloud projects list --format="[list,no-heading](name,project_id)" > /tmp/project-list && cp /tmp/project-list ~/.cache/project-list
}

function configs {
  if [[ -z "${1}" ]]; then
    echo "${active_config}"
    exit
  else
    configs=$(gcloud config configurations list --format="[no-heading](name)" --filter="name ~ ${1}")
  fi
  if [[ "${configs}" == "" ]]; then 
    echo "no match"
    exit
  fi
  if [[ $(wc -l <<< "${configs}") -gt 1 ]]; then
    gcloud config configurations activate $(fzf <<< "${configs}")
  else
    gcloud config configurations activate "${configs}"
  fi 
}

if [[ ! -f ~/.cache/project-list ]]; then
  refresh
fi

if [[ -z "${1}" ]]; then
  #gcloud config get-value project
  blankmatch
else
  case "${1}" in 
    help ) help;;
    refresh ) refresh;; 
    list ) cat ~/.cache/project-list;;
    current ) echo "${current_project}";;
    -c ) configs "${2}";;
    * ) match "${1}" ;;
  esac
fi
