# API

This scripts are designed to simplify the deployment and configuration of an application using EzAppConfig and Helm charts.
API folder contains the scripts and configuration files related to the EzAppConfig cli API.

* [Prerequisites](#prerequisites)
* [Getting started](#getting-started)
* [Configuration](#configuration)
* [Usage](#usage)
  * [How to install](#install-the-application)
  * [How to upgrade](#upgrade-the-application)
  * [How to delete](#delete-the-application)
* [Chartmuseum](#chartmuseum)
  * [How to upload chart](#build-and-upload-the-chart-tarball-to-chartmuseum)
  * [How to delete chart](#delete-the-chart-tarball-from-chartmuseum)
  * [Optional/Troubleshooting](#optionaltroubleshooting)
* [EzAppConfig Spec Api](templates/README.md)

## Prerequisites

1. Linux or MacOS machine (windows not tested)

2. The kube config of the Workload EZUA cluster

3. Ensure that the following tools are installed:

- [helm](https://github.com/helm/helm/releases/tag/v3.14.3)  v3.14.3
- [jq](https://github.com/jqlang/jq/releases/tag/jq-1.7.1)  v1.7.1
- [yq](https://github.com/mikefarah/yq/releases/tag/v4.43.1) v4.43.1
- [kubectl](https://github.com/kubernetes/kubernetes/releases/tag/v1.26.14) v1.26.14

    This list of utilities was used during configuration and testing of the application. The versions indicated in the list are recommended. The use of older versions has not been tested in this example. If you are using newer versions, make sure they are backwards compatible.

    If you do not have some of the above utilities, please follow the instructions on how to install the utility on your operating system from the official source.

## Getting started

1. Clone the repository:

```bash
git clone git@github.com:HPEEzmeral/byoa-tutorials.git
```

2. Ensure that the required tools are installed by running the following commands:

```bash
cd api/tooling/
./check_required_tools.sh
```
You will see the following output:

```
Checking required tools...
- Helm version: v3.14.3
- jq version: 1.7.1
- yq version: v4.43.1
- kubectl version: v1.26.14
Required tools checked.
```

3. Run the folowing command to see usage help:

```bash
./bootstrap.sh
```

You will see the following output

```
Usage: ./tooling/bootstrap.sh <COMMAND> [ARGUMENTS]

Commands:
        install
        upgrade
        delete
        build_and_upload_chart_bundle
                Uploads the current chart version to chartmuseum
        delete_chart_bundle [chart_version]
                Deletes the chart version from chartmuseum, if chart_version is not provided, current version is passed
```

## Configuration

To configure the API, modify the bootstrap specific constants in [bootstrap.sh](tooling/bootstrap.sh) file and modify the [configure](tooling/bootstrap.sh?#L30) function.

Constants:

* `CHART_PATH`: Path to the application helm chart.

* `EZAPPCONFIG_TEMPLATE_PATH`: Path to the ezappconfig-template.yaml file.

* `EZAPPCONFIG_PATH`: Path to the configured ezappconfig.yaml file.

* `EZAPP_LOGO_PATH`: Path to the application logo PNG file.

### Configure the EzAppConfig for the application

The configure function is used to configure the values.yaml file for a specific application chart. It performs the following steps:

* Uses the yq tool to modify the values.yaml file for the chart. It updates the following fields:
Use this section to set override values for the application.

* `ezua.virtualService.endpoint` is set to the value of the ENDPOINT variable
Used to provide an endpoint be available from the UI App tile.

* `airgap.registry.url` is required if you going to install the application on airgapped environment.
set to the value of the AIRGAP_REGISTRY variable

* The modified content is then written to the `${TMP_VALUES_PATH}` file.

* `create_ezappconfig_from_template` function create the EzAppConfig from a template, using the values from the `${TMP_VALUES_PATH}` file.

* `build_and_upload_chart_bundle` function builds and upload the chart tarball to the chartmuseum.

**_NOTE:_** `${TMP_VALUES_PATH}` this is a local variable used to specify the path to the modified `values.yaml` -> `tmp.yaml` file. Don't modify it.

**_NOTE:_** if the application chart version already present in the chartmuseum, it will not override it. Bump the chart version first in `Chart.yaml` to use higer chart version or [delete chart from chartmuseum](#delete-the-chart-tarball-from-chartmuseum) before try to upload new chart tarball.Before you begin installing the application, please read the [configuration](#configuration) section.

## Usage

### Install the application:

```bash
./bootstrap.sh install
```

### Upgrade the application:

```bash
./bootstrap.sh upgrade
```

### Delete the application:

```bash
./bootstrap.sh delete
```

## Chartmuseum

[ChartMuseum](https://chartmuseum.com/) is an open-source, easy to deploy, Helm Chart Repository server.

EZUA platform uses Chartmuseum to manage helm charts for an applications.
TODO describe that EZUA chartmuseum it is internal EZUA service
TODO describe diagram how chartmuseum EzAppConfig and EZUA objects interact

Here is provided several helper functions to manage Application helm chart within EZUA platform


TODO describe that it is an optional step

```
cd api/tooling
```

### Build and upload the chart tarball to Chartmuseum:

```bash
./bootstrap.sh build_and_upload_chart_bundle
```

### Delete the chart tarball from Chartmuseum:

```bash
./bootstrap.sh delete_chart_bundle [<chart_version>]
```
 The optional <chart_version> parameter is used to specify a specific chart version to delete. If not provided, the current version from `${CHART_PATH}/Chart.yaml` will be used.


### Optional/Troubleshooting 

\#TODO
