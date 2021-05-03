Acrolinx Platform 2021.03 Helm Chart
===========================================================

This Helm chart installs the Acrolinx Platform 2021.03 and the Acrolinx Core Platform Operator 0.8.13 in a single node Kubernetes cluster.

About
-------

[Acrolinx][acrolinx-platform] is a software to improve content quality.
It scores your content based on style, grammar, terminology, and tone of voice.
The higher your Acrolinx Score, the better your content.
It works with over 30 authoring tools and helps writers to enhance texts.
Visit our [blog][acrolinx-blog] to learn why better content results in better business.
See the [release notes][acrolinx-release-notes] for what's new in version 2021.03.

Since version 2021.02, the Acrolinx Platform has a [containerized][docker-what-is-a-container] architecture that's running in a Kubernetes cluster.
[Kubernetes][kubernetes-home] (K8s) is an open-source system for automating deployment, scaling, and management of containerized applications.
It has a large, rapidly growing ecosystem.
Kubernetes services, support, and tools are widely available.

The Acrolinx Core Platform Operator is an [extension][kubernetes-operator-pattern] to Kubernetes.
It bootstraps the Core Platform and keeps it in the desired state.
You can think of it as the knowledge of a human operator written in code.

[Helm][helm-home] is a "package manager" for Kubernetes.
Helm helps define, package, and ship complex Kubernetes applications as so-called [charts][helm-charts].
Charts can be installed, upgraded, uninstalled, or rolled back with simple commands.


Prerequisites
--------------

### Software and Environment

You need administrative access to a Kubernetes cluster, [Helm 3][helm-3] and [`kubectl`][kubernetes-kubectl].

Moreover, you need access to the Acrolinx Platform images.
Acrolinx distributes the Core Platform images via a private container registry.
The credentials for that registry are temporary.
They can be obtained and refreshed through the [Acrolinx download area][acrolinx-docs-download-area].
[The Helm installation can perform the refreshing automatically][this-creds].

### Namespaces

Before installing the Core Platform, you need to create two [namespaces][kubernetes-namespaces]:
* `acrolinx-system`: The namespace in which the operator is running.
* `acrolinx`: The namespace in which the platform is running.
* Optionally a third namespace for the [Helm release][helm-concepts] data.
```shell
kubectl create namespace acrolinx-system
kubectl create namespace acrolinx
```
(The namespace names can be customized in the chart's [values][helm-value-files].)

With the current version of this Helm chart, the operator and the Core Platform _need_ to be installed to different namespaces.

[Helm 3 stores release data in the same namespace as the release][helm-release-data-namespace].
Helm release data is needed for the [Helm history][helm-history], for rollbacks and for deinstallation.
The "release namespace" is the one you specify with the `--namespace <namespace>` flag when installing a Helm chart on the [command line][this-usage].
If you omit that flag, your release data get stored in the `default` namespace.
Use `--namespace acrolinx-system` to store your release data in the same namespace as the Acrolinx Core Platform Operator.
Of course, you can also use a namespace of your own choice.

This Helm chart needs the `--namespace` cmd-line flag only to specify the location for the release data.
The namespaces for platform and operator are specified via the [values][helm-value-files] `operator.namespace` and `platform.namespace`, respectively.

The Helm chart doesn't manage the namespaces because uninstalling a release would delete them.
And potentially all additions that were made besides the Helm chart.
So it's safer to presume that the namespaces already exist and are a responsibility of the cluster administrator.


Usage
-------

### The Deliverable

You can find the Acrolinx Helm repository with all our charts at [https://acrolinx.github.io/helm/][acrolinx-helm-repo].

Helm charts can be distributed as plain archives, such as `acrolinx-platform-0.8.13+2021.03.tgz`, or via a [Helm repository][helm-repos].
If you're installing from a repository, you may have to [add that repository][helm-repo-add] first.
You can even unpack the archive and run the installation from the resulting directory.
For the [installation command-line syntax][helm-install] it makes no difference.
The chart name from the repository, the `.` or the `.tgz` file all appear in the same position.

### Exploration

If you aren't already familiar with the Acrolinx Standard Stack Helm deployment, it's a good idea to start with a quick exploration of the chart.

To [see basic information about the chart][helm-show-chart], run:
```shell
helm show chart acrolinx-platform
```

To [see this README][helm-show-readme], run:
```shell
helm show readme acrolinx-platform
```

To [see the effective default values][helm-show-values], run
```shell
helm show values acrolinx-platform
```

### Configuration

Before you install the Acrolinx Platform to Kubernetes, you may want to modify some settings.

#### Customize the Values File
Run
```shell
helm show values acrolinx-platform > custom-values.yaml
```
Move the resulting custom [values][helm-value-files] file to a location where it can persist, say `acrolinx.yaml`.
The comments above the individual settings should give good hints what you can do.
Make the desired modifications.

#### Registry Credentials

The Acrolinx Platform and operator images are distributed via a private Acrolinx registry.
Temporary credentials for that registry are available via the [Acrolinx download area][acrolinx-docs-download-area].
The Helm chart manages a job to refresh those credentials automatically.
To do so, it needs credentials for the download area.
They're configured in the `images.download_area_user` and `images.download_area_pwd` properties:
```yaml
images:
  download_area_user: "<user name for Acrolinx download area>"
  download_area_pwd: "<password for Acrolinx download area>"
```

If you copied the images to your own private registry and are pulling from there, just omit (remove) the `download_area_.*` settings.
Instead, use:
```yaml
images:
  username: "<username for private registry>"
  password: "<password for private registry>"
```

#### User
For security reasons, the Core Platform services shouldn't run with `root` privileges.
Please create a dedicated unprivileged user, say `acrolinx` and use that user's ID and GID for the platform services:
```yaml
platform:
  spec:
    securityContext:
      runAsUser: <id -u acrolinx>
      runAsGroup: <id -g acrolinx>
```
The `acrolinx` user should also own the [mounted configuration directory described below][this-mount-overlay].

#### Mount the Configuration Directory

If you have an existing Acrolinx installation, we recommend that you mount your [configuration directory][acrolinx-docs-configuration-directory] into the cluster.
(Copy the directory to the cluster node, if necessary. In older installations it used to be `.config/Acrolinx/ServerConfiguration`)
If you're creating an Acrolinx installation from scratch, please dedicate an empty directory on your single cluster node to the Acrolinx configuration, say `/home/acrolinx/config`.
In your custom values file, set:
```yaml
platform:
  spec:
    securityContext:
      runAsUser: <acrolinx user id>
      runAsGroup: <acrolinx group id>
    coreServer:
      overlayDirectory:
        volumeSource:
          hostPath:
            ### Path to the custom configuration directory on the host system.
            path: /home/acrolinx/config
```

#### Database Connections

Add the settings for the Target service database to `persistence.credentials`.

**Optionally** add the settings for the terminology database, the reporting database, and the JReport databases to `persistence.properties`.
:warning: Those settings are overridden by the settings in the `<overlay-folder>/server/bin/persistence.properties` file.
Remove that file if you want to keep the settings in the custom values.

If you want to test the Acrolinx Platform without any external databases, remove any `persistence.credentials` and enable the cluster internal test backends:
```yaml
platform:
  persistence:
    installTestDB: true
```

### Installation and Upgrades

The canonical command to install the Acrolinx Platform via Helm is:
```shell
helm install acrolinx --values <custom values file> acrolinx-platform
```
You can also set individual values on the command line. (See the [Helm install reference][helm-install]).

Run
```shell
helm upgrade acrolinx --values <custom values file> acrolinx-platform --namespace acrolinx-system
```

Acrolinx will deliver a new Helm chart for every Standard Stack Acrolinx Platform version.

### Sanity Check

After the installation or upgrade wait for a while. 
Depending on how many images need to be pulled, it may take several minutes for the Core Platform to start.
```shell
kubectl wait coreplatform acrolinx  --for condition=Ready --timeout=10m -n acrolinx
```

To see a summary of the platform status, run:
```shell 
kubectl get coreplatform acrolinx -o jsonpath="{.status.summary}" -n acrolinx | jq
```
For all status details:
```shell
kubectl get coreplatform acrolinx -o jsonpath="{.status}" -n acrolinx | jq
```


### Troubleshooting

What can possibly go wrong? 

To find out you can use our [support package script][acrolinx-helm-repo-support-package-script]. 
Just execute the script as described [here][acrolinx-helm-repo-support-package-script-manual]. Send the resulting `.tgz` file to [Acrolinx Support][acrolinx-support].




[acrolinx-blog]: https://www.acrolinx.com/blog/
[acrolinx-docs]: https://docs.acrolinx.com/doc/en
[acrolinx-docs-configuration-directory]: https://docs.acrolinx.com/coreplatform/latest/en/advanced/the-configuration-directory
[acrolinx-docs-download-area]: https://docs.acrolinx.com/coreplatform/latest/en/acrolinx-on-premise-only/maintain-the-core-platform/download-updated-software
[acrolinx-helm-repo]: https://acrolinx.github.io/helm/
[acrolinx-helm-repo-support-package-script]: https://acrolinx.github.io/helm/resources/core-platform/tools/support-package.sh
[acrolinx-helm-repo-support-package-script-manual]: https://acrolinx.github.io/helm/resources/core-platform/tools/support-package-user-manual.md
[acrolinx-home]: https://www.acrolinx.com
[acrolinx-platform]: https://www.acrolinx.com/the-acrolinx-content-strategy-governance-platform/
[acrolinx-release-notes]: https://docs.acrolinx.com/coreplatform/2021.03/en/acrolinx-core-platform-releases/acrolinx-release-notes-including-subsequent-service-releases 
[acrolinx-support]: https://support.acrolinx.com/hc/en-us
[docker-what-is-a-container]: https://www.docker.com/resources/what-container
[helm-3]: https://helm.sh/blog/helm-3-released/
[helm-charts]: https://helm.sh/docs/topics/charts/
[helm-concepts]: https://helm.sh/docs/intro/using_helm/#three-big-concepts
[helm-history]: https://helm.sh/docs/helm/helm_history/
[helm-home]: https://helm.sh/
[helm-install]: https://helm.sh/docs/helm/helm_install/
[helm-release-data-namespace]: https://helm.sh/docs/faq/#release-names-are-now-scoped-to-the-namespace
[helm-repo-add]: https://helm.sh/docs/intro/quickstart/#initialize-a-helm-chart-repository
[helm-repos]: https://helm.sh/docs/topics/chart_repository/
[helm-value-files]: https://helm.sh/docs/chart_template_guide/values_files/
[helm-show-chart]:https://helm.sh/docs/helm/helm_show_chart/
[helm-show-readme]: https://helm.sh/docs/helm/helm_show_readme/
[helm-show-values]: https://helm.sh/docs/helm/helm_show_values/
[kubernetes-home]: https://kubernetes.io/
[kubernetes-kubectl]: https://kubernetes.io/docs/reference/kubectl/overview/
[kubernetes-namespaces]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[kubernetes-operator-pattern]: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
[this-creds]: #Registry-Credentials
[this-mount-overlay]: #Mount-the-Configuration-Directory
[this-usage]: #Usage
