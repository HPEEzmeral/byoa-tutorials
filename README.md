# EzUA Bring Your Own Application tutorials

Welcome to the EzUA Bring Your Own Application (BYOApp) tutorials repository! This is the official source for demo and tutorial related to the EzUA 
platform. The HPE Ezmeral Unified Analytics Software is usage-based Software-as-a-Service (SaaS) that fully manages,
supports, and maintains hybrid and multi-cloud modern analytical workloads through open-source tools.
This repo provide the demo and example how to configure, package, manage and deploy a helm chart based application on EzUA platform.

## Repository Structure

- [Tutorial](tutorial/README.md): e2e tutorial how to deploy an application on EZUA via Bring Your Own Application (BYOApp) feature.
- [Api](api/README.md): contains scripts designed to simplify the deployment and configuration of an application using EzAppConfig CR and the helm charts.
- [EzAppConfig](api/templates/README.md): documentation and example template of EzAppConfig CR api.
- [test-app](test-app): contains helm chart sources of the demo `test-app` application .
- [upload-bundle-job](upload-bundle-job/README.md): contains files used to build and upload bundle image with a list of versions of the `test-app` application (for demo usage).
- [tarballs](tarballs): contains list of versions of the helm packages (tarballs) of the `test-app` application (for demo usage).
- [ezua](ezua): contains helm templates intended for integration an application helm chart with the EZUA BYOApp feature.

## Demo

Navigate to the [`api`](api) directory to find a [Getting Started](api/README.md#getting-started) guide how to deploy the demo application `test-app`. This demo are designed to help you grasp what the EzUA BYOApp feature.

## Prerequisites

1. Linux or MacOS machine (windows not tested).

2. The kube config of the EzUA cluster.

3. Ensure that the following tools are installed:

- [helm](https://github.com/helm/helm/releases/tag/v3.14.3)  v3.14.3
- [jq](https://github.com/jqlang/jq/releases/tag/jq-1.7.1)  v1.7.1
- [yq](https://github.com/mikefarah/yq/releases/tag/v4.43.1) v4.43.1
- [kubectl](https://github.com/kubernetes/kubernetes/releases/tag/v1.26.14) v1.26.14

    This list of utilities was used during configuration and testing of the application. The versions indicated in the list are recommended. The use of older versions has not been tested in this example. If you are using newer versions, make sure they are backwards compatible.

    If you do not have some of the above utilities, please follow the instructions on how to install the utility for your OS from the official source.

4. This demo and tutorial assume you have a basic knowladge of the [Helm charts](https://helm.sh/) and [Bash](https://www.gnu.org/software/bash/) scripting.
