#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}/common.sh"

# <BOOTSTRAP> Bootstrap specific constants [start]
#path to the application helm chart
CHART_PATH="${SCRIPT_DIR}/../../test-app"
#path to the ezappconfig-template.yaml file
EZAPPCONFIG_TEMPLATE_PATH="${SCRIPT_DIR}/../templates/ezappconfig-test-app-template.yaml"
#path to the configured ezappconfig.yaml file
EZAPPCONFIG_PATH="${EZAPPCONFIG_TEMPLATE_PATH//-template.yaml/.yaml}"
#path to the application logo png file
EZAPP_LOGO_PATH="${SCRIPT_DIR}/../templates/logo.png"
# <BOOTSTRAP> Bootstrap specific constants [end]

# Build and upload chart tarball to chartmuseum locally (replacement for build_bundle.sh)
build_and_upload_chart_bundle() {
    upload_chart_tarball "${CHART_PATH}"
    return $?
}

# Delete chart tarball from chartmuseum locally. 1st argument is the chart version, if not provided, current one is used
delete_chart_bundle() {
    delete_chart_tarball "${CHART_PATH}" $1
    return $?
}

# Configure the EzAppConfig for the application with values.yaml
configure() {
    pushd "${SCRIPT_DIR}" > /dev/null

    # <APP-UNIQ> Application specific values.yaml configuration for chart [start]
    export AIRGAP_REGISTRY="\${AIRGAP_REGISTRY}"
    export ENDPOINT="\${RELEASE_NAME}-\${NAMESPACE}.\${DOMAIN_NAME}"

    yq '.ezua.virtualService.endpoint = strenv(ENDPOINT) |
        .airgap.registry.url = strenv(AIRGAP_REGISTRY) |
        .resources.limits.cpu = "200m" |
        .resources.limits.memory = "256Mi"
    ' "${CHART_PATH}/values.yaml" > ${TMP_VALUES_PATH}
    # <APP-UNIQ> Application specific values.yaml configuration for chart [end]

    # Create ezAppConfig from template and set the values from configured above tmp.yaml
    create_ezappconfig_from_template

    popd > /dev/null

    build_and_upload_chart_bundle
    return $?
}

# Interface function for installation
install() {
    local ezapp_name=$(yq '.metadata.name' "${EZAPPCONFIG_TEMPLATE_PATH}")
    configure
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Could not configure ${ezapp_name}" && return 1
    fi

    kubectl apply -f "${EZAPPCONFIG_PATH}"
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Could not apply ${EZAPPCONFIG_PATH}" && return 1
    fi

    wait_ezapp_status "$ezapp_name" 3600
    return $?
}

# Interface function for upgrade
upgrade() {
    install
    return $?
}

# Interface function for deletion
delete() {
    kubectl delete -f "${EZAPPCONFIG_TEMPLATE_PATH}"
    return $?
}

show_help_if_command_is_empty $@

$@
