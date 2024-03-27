#!/bin/bash

TMP_VALUES_PATH="${SCRIPT_DIR}/tmp.yaml"
BUILD_DIR="${SCRIPT_DIR}/../build"

test -d ${BUILD_DIR} || mkdir -p ${BUILD_DIR}

function isConnectedEnv() {
    local IS_AIRGAP="$(kubectl get cm -n ezua-system ezua-cluster-config -o jsonpath='{.data.cluster\.isAirgap}' 2> /dev/null)"
    if [[ ${IS_AIRGAP} == "true" ]]; then
        IS_CONNECTED_ENV="false"
    else
        IS_CONNECTED_ENV="true"
    fi

    echo $IS_CONNECTED_ENV
}

function wait_ezapp_status() {
    #ezappconfig Status.Status terminal state enum
    local terminal_states="ready error warning"
    local ezapp_name=$1
    local timeout=$2
    local start_ts=$(date +%s)
    echo "ezappconfig name: $ezapp_name"
    echo "Wait until the status get into [$terminal_states]"
    while true; do
        local now_ts=$(date +%s)
        local prev_state=$state
        local state="$(kubectl get ezappconfig $ezapp_name -o jsonpath={.status.status} 2> /dev/null)"
        local retryCnt="$(kubectl get ezappconfig $ezapp_name -o jsonpath={.status.retryCnt} 2> /dev/null)"
        local backoffLimit="$(kubectl get ezappconfig $ezapp_name -o jsonpath={.spec.backoffLimit} 2> /dev/null)"
        if ! [ "$prev_state" == "$state" ]; then printf '\n'; fi
        local elapsed_seconds=$(( now_ts - start_ts ))
        local hours=$((elapsed_seconds / 3600))
        local minutes=$(( (elapsed_seconds % 3600) / 60 ))
        local seconds=$((elapsed_seconds % 60))
        local formated_elapsed_time="$(printf "%02d:%02d:%02d" $hours $minutes $seconds)"
        printf "Status: %-12s RetryCnt: %-2s Time: %-20s" "$state" "$retryCnt" "$formated_elapsed_time"
        if [[ $terminal_states =~ (^|[[:space:]])$state($|[[:space:]]) ]]; then
            if [[ $state == "ready" ]] ||
                [ "$retryCnt" -gt "$backoffLimit" ]; then
                echo
                echo "Condition met"
                break;
            fi
        fi
        if [ $elapsed_seconds -gt $timeout ]; then
            echo
            echo "Finished by timeout"
            return 1
        fi
        sleep 10
        printf $'\r'
    done
    if [[ "ready" == "$(kubectl get ezappconfig $ezapp_name -o jsonpath={.status.status})" ]]; then
        echo "app $ezapp_name is in ready state"
    else
        echo "ERROR: app $ezapp_name is in failed state"
        local err_msg=$(kubectl get ezappconfig $ezapp_name -o jsonpath={.status.failureReason})
        echo "FAILURE REASON: ${err_msg}"

        return 1
    fi
    return 0
}

__is_running_in_k8s_cluster() {
    if [[ -f /var/run/secrets/kubernetes.io/serviceaccount/token ]]; then
        return 0
    else
        return 1
    fi
}

__is_reachable_url() {
    local url=$1
    local timeout=5
    curl -fsS "$url" -m $timeout -o /dev/null 2> /dev/null
    if [[ $? -ne 0 ]]; then
        return 1
    else
        return 0
    fi
}

__random_unused_port() {
    local random_port_fallback=58059
    local port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()' 2> /dev/null)
    if [[ $? -ne 0 ]]; then
        echo $random_port_fallback
    fi
    echo $port
}

__chartmuseum_port_forward_pid_filepath() {
    echo "/tmp/chartmuseum_port_forward_pid"
}

__get_locally_available_chartmuseum_url() {
    local chartmuseum_svc_name="chartmuseum"
    local chartmuseum_svc_ns="ez-chartmuseum-ns"
    local chartmuseum_svc_port="8080"
    local chartmuseum_k8s_domain="${chartmuseum_svc_name}.${chartmuseum_svc_ns}"
    local chartmuseum_k8s_url="http://${chartmuseum_k8s_domain}:${chartmuseum_svc_port}"
    #port-forward chartmuseum svc if it's not reachable
    local chartmuseum_local_url="${chartmuseum_k8s_url}"
    if ! __is_running_in_k8s_cluster; then
        echo "INFO: Not running in k8s cluster, trying to port-forward chartmuseum from $chartmuseum_k8s_url" >&2
        local random_port=$(__random_unused_port)
        kubectl port-forward svc/$chartmuseum_svc_name -n $chartmuseum_svc_ns $random_port:$chartmuseum_svc_port >&2 &
        echo $! > $(__chartmuseum_port_forward_pid_filepath)
        chartmuseum_local_url="http://localhost:${random_port}"
        until __is_reachable_url "$chartmuseum_local_url"; do
            sleep 1
        done
        echo "INFO: Port-forwarding $chartmuseum_k8s_url to $chartmuseum_local_url" >&2
    fi
    echo "$chartmuseum_local_url"
}

__terminate_chartmuseum_port_forward_on_exit_if_needed() {
    if [[ -f $(__chartmuseum_port_forward_pid_filepath) ]]; then
        local port_forward_pid="$(cat $(__chartmuseum_port_forward_pid_filepath))"
        trap "echo 'INFO: Stopping port-forwarding chartmuseum' >&2; kill $port_forward_pid" EXIT
        rm $(__chartmuseum_port_forward_pid_filepath)
    fi
}

function upload_chart_tarball() {
    local chartmuseum_local_url="$(__get_locally_available_chartmuseum_url)"
    __terminate_chartmuseum_port_forward_on_exit_if_needed
    echo "INFO: Trying to upload chart tarball to $chartmuseum_local_url"
    #prepare chart tarball
    local chart_path="$1"
    local version=$(helm inspect chart "$chart_path" 2>/dev/null | yq .version)
    local name=$(helm inspect chart "$chart_path" 2>/dev/null | yq .name)
    local tarball="$name-$version.tgz"
    helm dependency update "$chart_path"
    helm package "$chart_path" -d "${BUILD_DIR}"
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Couldn't package helm charts in $chart_path" && return 1
    fi
    #push chart tarball to chartmuseum
    local chart_tarball_path="${BUILD_DIR}/${tarball}"
    local upload_chart_url="${chartmuseum_local_url}/api/charts"
    local timeout=15
    local status_code="$(curl -sS --data-binary "@${chart_tarball_path}" "${upload_chart_url}" -m $timeout -w '%{http_code}' -o /dev/null)"
    if [[ "$status_code" != "201" && "$status_code" != "409" && "$status_code" -ge 400 ]]; then
        echo "ERROR: Couldn't upload chart tarball $tarball to $chartmuseum_local_url, status code was $status_code" && return 1
    elif [[ "$status_code" == "201" ]]; then
        echo "INFO: Chart tarball $tarball uploaded to $chartmuseum_local_url"
    elif [[ "$status_code" == "409" ]]; then
        echo "INFO: Chart tarball $tarball already exists in $chartmuseum_local_url, skipping upload"
    else
        echo "INFO: Tried to upload chart tarball $tarball to $chartmuseum_local_url, chartmuseum returned status code $status_code"
    fi
    return 0
}

function delete_chart_tarball() {
    local chartmuseum_local_url="$(__get_locally_available_chartmuseum_url)"
    __terminate_chartmuseum_port_forward_on_exit_if_needed
    echo "INFO: Trying to delete chart tarball from $chartmuseum_local_url"
    local chart_path="$1"
    local version=${2:-$(helm inspect chart "$chart_path" 2>/dev/null | yq .version)}
    local name=$(helm inspect chart "$chart_path" 2>/dev/null | yq .name)
    #delete chart tarball from chartmuseum
    local delete_chart_url="${chartmuseum_local_url}/api/charts/${name}/${version}"
    local timeout=10
    local status_code="$(curl -sS -X DELETE "${delete_chart_url}" -m $timeout -w '%{http_code}' -o /dev/null)"
    if [[ "$status_code" != "200" && "$status_code" != "404" && "$status_code" -ge 400 ]]; then
        echo "ERROR: Couldn't delete chart $name v$version from $chartmuseum_local_url, status code was $status_code" && return 1
    elif [[ "$status_code" == "200" ]]; then
        echo "INFO: Chart $name v$version deleted from $chartmuseum_local_url"
    elif [[ "$status_code" == "404" ]]; then
        echo "INFO: Chart $name v$version doesn't exist in $chartmuseum_local_url, skipping delete"
    else
        echo "INFO:Tried to delete chart $name v$version from $chartmuseum_local_url, chartmuseum returned status code $status_code"
    fi
    return 0
}

__set_last_retry_timestamp_if_ezappconfig_in_warning_state() {
    local warning_state="warning"
    local current_state=$(kubectl get -f "${EZAPPCONFIG_PATH}" -o jsonpath={.status.status} --ignore-not-found)
    if [[ "$current_state" == "$warning_state" ]]; then
        yq -i e 'with(.ezua.retries.lastRetryTimestamp; . = now | . style="double")' ${TMP_VALUES_PATH:-"tmp.yaml"}
    fi
}

function create_ezappconfig_from_template() {
    export CHART_VERSION=$(yq '.version' "${CHART_PATH}/Chart.yaml")
    export APP_VERSION=$(yq '.appVersion' "${CHART_PATH}/Chart.yaml")
    APP_LOGO=""
    if [[ -f ${EZAPP_LOGO_PATH:-logo.png} ]]; then
        APP_LOGO=$(base64 < ${EZAPP_LOGO_PATH:-logo.png} | tr -d '\n' 2> /dev/null)
    fi
    export APP_LOGO

    cp "${EZAPPCONFIG_TEMPLATE_PATH}" "${EZAPPCONFIG_PATH}"
    if [[ -f "${TMP_VALUES_PATH}" ]]; then
        # Set lastRetryTimestamp if ezappconfig is in warning state in order to trigger an upgrade
        __set_last_retry_timestamp_if_ezappconfig_in_warning_state
        IFS= read -rd '' output < <(cat ${TMP_VALUES_PATH})
        output=$output yq -iP e '.spec.values = strenv(output)' "${EZAPPCONFIG_PATH}"
        rm ${TMP_VALUES_PATH}
    fi

    yq -i e '
        .spec.logoImage = strenv(APP_LOGO) |
        .spec.chartVersion = strenv(CHART_VERSION) |
        .spec.version = strenv(APP_VERSION)
    ' "${EZAPPCONFIG_PATH}"
}

function show_help_if_command_is_empty() {
    if [[ "$1" == "" ]]; then
        echo -e "Usage: $0 <COMMAND> [ARGUMENTS]"
        echo -e "\nCommands:"
        echo -e "\tinstall"
        echo -e "\tupgrade"
        echo -e "\tdelete"
        echo -e "\tbuild_and_upload_chart_bundle\n\t\tUploads the current chart version to chartmuseum"
        echo -e "\tdelete_chart_bundle [chart_version]\n\t\tDeletes the chart version from chartmuseum, if chart_version is not provided, current version is passed"
        exit 0
    fi
}
