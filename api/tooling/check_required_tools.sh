#!/bin/bash

# Verify that the required tools are installed
check_required_tools() {
  echo "Checking required tools..."

  local error=0
  
  # Check Helm version
  helm_version=$(helm version --short 2>/dev/null | cut -d":" -f2)
  if [[ -z $helm_version ]]; then
    echo "Error: Failed to retrieve Helm version."
    error=1
  else
    echo "- Helm version: ${helm_version}"
  fi

  # Check jq version
  jq_version=$(jq --version | cut -d"-" -f2)
  if [[ -z $jq_version ]]; then
    echo "Error: Failed to retrieve jq version."
    error=1
  else
    echo "- jq version: ${jq_version}"
  fi

  # Check yq version
  yq_version=$(yq --version | cut -d" " -f4)
  if [[ -z $yq_version ]]; then
    echo "Error: Failed to retrieve yq version."
    error=1
  else
    echo "- yq version: ${yq_version}"
  fi

  # Check kubectl version
  kubectl_version=$(kubectl version --client -o=yaml | grep gitVersion | cut -d" " -f4)
  if [[ -z $kubectl_version ]]; then
    echo "Error: Failed to retrieve kubectl version."
    error=1
  else
    echo "- kubectl version: ${kubectl_version}"
  fi

  if [[ $error -eq 1 ]]; then
    echo "Not all required tools are pass the version check"
    return 1
  else
    echo "Required tools checked."
    return 0
  fi
}

check_required_tools
