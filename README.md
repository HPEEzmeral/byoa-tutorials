# EZUA Bring Your Own Application example

This repo provide an example of configure, package and deploy helm chart based application on EZUA cluster using EzAppConfig CR.

* ### [Tutorial](tutorial/README.md) how to integrate application helm chart to deploy on EZUA via Bring Your Own Application feature.
* ### [api](api/README.md) contains scripts designed to simplify the deployment and configuration of an application using EzAppConfig and Helm charts.
* ### [EzAppConfig](api/templates/README.md) custom resource api.
* ### [test-app](test-app) contains helm chart sources of the demo application `test-app`.
* ### [upload-bundle-job](upload-bundle-job/README.md)  contains files used to build and upload bundle image with a list of versions for `test-app` application (for demo usage)
* ### [tarballs](tarballs) contains list of helm packages (tarballs) of application `test-app` of various versions. Used to create a boundle for demo.
* ### [ezua](ezua) contains templates intended for configuring the Application helm chart for integration with the EZUA platform.

