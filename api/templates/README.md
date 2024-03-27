# EzAppConfig custom resource API

[!NOTE] TODO add description waht EzAppConfig custom resurce is

* [EzAppConfig Spec api](#ezappconfig-spec-api)
* [`test-app` ezappconfig template](ezappconfig-test-app-template.yaml)

## EzAppConfig Spec API

The `EzAppConfig` describes the desired state of the Application.

| Name | Type | Description |
| ---- | ---- | ----------- |
| Name | string, required, immutable | The Name field must correspond to the name of the helm chart in the Chart.yaml file. `Immutable` |
| ReleaseName | string, optional, immutable | The release name for the Application if not specified Name used by default. |
| Version | string, optional, immutable | The Application version. This field would be deprecated in next releases. The app version fetched from the helm chart |
| ChartVersion | string, required | The chart version of the Application. |
| Options | map[string]string, optional | The options used to path helm options for install/upgrade operations |
| Values | string, optional | The values of the EzAppConfig, overrides values from default values.yaml of the Application chart. |
| Retry | bool, optional | Indicates whether to retry last action (Install/Upgrade/Update/Delete) if failed. |
| BackoffLimit | int64, optional | The number of retries before marking the EzAppConfig as failed. Default is 3. |
| Description | string, optional | The description of the Application. |
| Category | string, required | The category of the Application |
| LogoImage | string, optional | The logo image of the Application, `base64` encoded png file |
| Label | string, optional | The name of the Application. Used to display the title of the application tile |

`spec.options` support list of helm options which may be used with helm command. This field has `map[string]string` type, all values should be stringified. If helm option is a boolean flag, then use `true` or `false` strings to set the value.

 * [install](https://helm.sh/docs/helm/helm_install/#options) Options passed for install command. Inherits `common` options.
    * `create-namespace` create the release namespace if not present
 * [upgrade](https://helm.sh/docs/helm/helm_install/#options) Options passed for upgrade command. Inherits `common` options.
    * `create-namespace`
    * `install` if a release by this name doesn't already exist, run an install
 * [uninstall](https://helm.sh/docs/helm/helm_uninstall/#options) Options passed for uninstall command. Inherits `common` options.
 * [common](https://helm.sh/docs/helm/helm/#options) Options inherited from parent commands
    * `debug` enable verbose output
    * `namespace` namespace scope for this release
    * `timeout` time to wait for any individual Kubernetes operation (like Jobs for hooks) (default 1h)
    * `wait` if set, will wait until all Pods, PVCs, Services, and minimum number of Pods of a Deployment, StatefulSet, or ReplicaSet are in a ready state before marking the release as successful. It will wait for as long as `timeout`

**_NOTE:_** For a more detailed description and use cases, see the [Helm documentation](https://helm.sh/docs/helm/).

`spec.category` responsible for which group the application will be displayed in. Supports the following values:

- `dataEngineering`
- `dataScience`
- `analytics`

`spec.chartVersion` used to specify desired Application chart version. It is a main field to controll the EzAppConfig status. Once EzAppConfig resource was created, controller apply the helm `install` operation. When this field is modified, controller try to apply the helm `upgrade` operation.

`spec.backoffLimit` The controller will restart operation in case of failure, if the total number of restarts is below backoffLimit. If the backoffLimit is reached the entire EzAppConfig status failed.