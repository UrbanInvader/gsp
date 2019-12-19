#!/bin/bash
#
# change google cloud projects more efficiently
# big thanks to https://github.com/junegunn/fzf

set -eo pipefail

if [[ ! $(fzf --version) ]]; then
  echo "fzf not installed, please install fzf"
  exit 1
fi

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
  target=$(grep -iPR "${target_project}" ${cache})
  tarray=()
  if [[ $(wc -l <<<${target}) > 1 ]]; then
    sel=$(fzf --border --height 20 <<< ${target} | awk '{print $NF}')
    gcloud config set project ${sel}
    echo "--- ${sel} ---"
    echo "${sel}" > ~/.cache/current-project
  else
    echo "--- $(awk '{print $NF}' <<< ${target}) ---"
    gcloud config set project $(awk '{print $NF}' <<< ${target})
    echo "$(awk '{print $NF}' <<< ${target})" > ~/.cache/current-project
  fi
}

function blankmatch {
  sel=$(fzf --border --height 20 < ~/.cache/project-list | awk '{print $NF}')
  gcloud config set project ${sel}
  echo "--- ${sel} ---"
  echo "${sel}" > ~/.cache/current-project
}

function refresh {
  echo "refreshing project list..."; gcloud projects list --format="[list,no-heading](name,project_id)" > /tmp/project-list && cp /tmp/project-list ~/.cache/project-list
}

if [[ ! -f ~/.cache/project-list ]]; then
  refresh
fi

if [[ -z ${1} ]]; then
  #gcloud config get-value project
  blankmatch
else
  case ${1} in 
    help ) help;;
    refresh ) refresh;; 
    list ) cat ~/.cache/project-list;;
    current ) cat ~/.cache/current-project;;
    * ) match $1
  esac
fi
