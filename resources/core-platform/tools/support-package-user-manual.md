# Observe Acrolinx Running on Top of Kubernetes

System observability is an important topic. It's all about ensuring everything is functioning as intended. Continuously monitoring and detecting errors or system malfunctions always crucial. In case of problems, we can help our Standard Stack customers troubleshooting.

## Support Package

Assuming that you’re running the Acrolinx Platform on a private (on-prem) host of yours as our Standard Stack customer. 

Creating a `Support Package` and handing over the collected data to our Support team at Acrolinx they can help you troubleshoot the operational issue that you might have encountered with.

The `Support Package Script` is a simple executable shell script that collects all collectable output at the execution time about your Kubernetes cluster. Then, the collected data (`Support Package`) can be sent to our Support team or attached to open tickets.

**Note:** *The script contains various `kubectl` command procedures to gather info about the existing Kubernetes resources and read logs from running pods. Executing the script shouldn’t have any affect on your running Acrolinx instance or cause downtime. Let us know if you encounter any error when using the script!* 

**Prerequisites:**
- `bzip2` installed on host.

### How to Use

**Note:** *Basic Linux knowledge is suggested.*

Supposed that you have the script `support-package.sh` (can be downloaded among the Acrolinx Platform deliverables from MADAM) and placed on your Linux-based Acrolinx installation host.

#### 1. Make Executable 
To make the `support-package.sh` file executable:
```
$ chmod +x support-package.sh
```
#### 2. Run
Execute the script to collect evidence:
```
$ ./support-package.sh
```

**Note:** *Try run the support package script frequently to capture relevant logs and error events when a problem is discovered in your deployment.*

When you run the script, it creates an archive of the collected data from your Kubernetes cluster. It contains details about the existing resources (Namespaces, Pods, ConfigMaps, ... ) related to the Acrolinx deployment. You can locate this archive in the script execution directory to check the collected output. 

The support package archive's naming format is `support-package-<timestamp_ISO_8601>` with extension `.tar.bz2`. 

Find the generated support package archive:
```
$ ls -la
// Output
drwx------. 6 ec2-user ec2-user  4096 Mar 19 08:31 .
drwxr-xr-x. 4 root     root        38 Mar 16 08:58 ..
-rw-rw-r--  1 ec2-user ec2-user 124818 Mar 19 12:33 support-package-20210319T123333Z.tar.bz2
-rwxrwxr-x  1 ec2-user ec2-user   5102 Mar 19 11:34 support-package.sh
```

This example output shows the following:
- The `support-package.sh` file is executable.
    - The first column shows the permission on a file or directory. (`x` means execute permission)
- A `support-package-20210319T123333Z.tar.bz2` archive exists.
    - This contains the data and logs collected by the script.

**Note:** *By default the collected data and `kubectl` outputs are written into a directory and being archived. When the script exists it deletes this temporary directory. Use the `-Z` flag to instruct the script to don't create an archive and leave the created directory on the host after the execution finished. See more about run modifiers in the `Run Options` sections.*

#### Troubleshoot

##### Output: `FATAL: bzip2 must be installed to create an archive.`
Running the script got the following output:
```
./support-package.sh
FATAL: bzip2 must be installed to create an archive.
```

To install the missing `bzip2` package:
```
$ sudo yum install bzip2
```

Try rerun the support package script.

**Note:** *This package required to compress the `tar` archive better.*

### Run Options
Using the supported run modifier options the script execution can be configured to get info from specific namespaces (in case your Acrolinx deployment is in another namespace than `default`) or to continue without archiving the collected details.

Use the `-h` flag to print help:
```
$ ./support-package.sh -h
```
Output should be written to your console:
```
Usage:

./support-package.sh [options]

Options:
  -h                Print this help message and exit.
  -o <directory>    Output directory (defaults to '.')
  -n <namespace>    Acrolinx namespace (defaults to current namespace: default)
  -s <namespace>    Operator installation namespace (defaults to acrolinx-system)
  -v                Verbose?
  -Z                Do not create an archive, and do not delete the support archive directory.

```

### Why Use the Support Package Script?
 
In case of noticing any issues with the Acrolinx Kubernetes deployment or in the application functionality itself running this script outside of the cluster can help collect evidence. 
Much of the collected data in the support package doesn't exist in the cluster forever. The created support package is needed to ensure that the evidence is captured timely. 

We can provide support and resolve the issue together based on the collected evidence.

Our Support team can even help you without handing over the support package. But it's important to have them preserved in order to use them in the investigation phase. You can use it as a source of information to help answer our Support team members' questions. What's happening with it afterward is entirely up to you. 

### What Is Being Collected?
At the time of writing the support package script collects the followings about your Kubernetes cluster and the existing resources in it:
- List of available Namespaces.
    - The script creates directories with matching name and place the namespace-related info into them.
- In general 
    - available logs (depends on log retention period) from existing pods and,
    - cluster events.
- The script execution time printed to file: `snapshot-time.txt` (simple timestamp).
- Merged kubeconfig settings (of namespace `default`) printed to file: `default-namespace.txt`.
- From the Acrolinx namespaces if exists (for example: `default`,`acrolinx-system`, `kube-system`, `olm`, `operators`).
    - Kubernetes resources (only from the `acrolinx-system` namespace):
        - ClusterServiceVersion (CSV)
        - InstallPlan (IP)
        - ConfigMap (CM)
    - Form the Acrolinx deployment namespace (default is the `default` K8s namespace, can be differ in your environment and specified at script run via flag `-n`).
    - Outputs of `kubectl` commands (in directories named after the `namespace`):
        - Get all resources: `kubectl get all` (k8s-all.txt)
        - Describe pods: `kubectl describe pods` (k8s-pods.txt)
        - Describe deployments: `kubectl describe deployments` (k8s-deployments.txt)

**Note:** *The script doesn't collect any Secret type Kubernetes resource. The collected ConfigMaps are also only from the Acrolinx deployment namespace!*

**Disclaimer:** *It's the customer's responsibility to check whether the collected content meets with their compliance and policies!*

See example `support-package` directory content tree:
```
$ tree support-package-20210319T083136Z/
support-package-20210319T083136Z/
├── acrolinx-system
│   ├── install-config-maps.txt
│   ├── install-plans.txt
│   ├── install-versions.txt
│   ├── k8s-all.txt
│   ├── k8s-deployments.txt
│   ├── k8s-operator-logs.txt
│   ├── k8s-other-logs.txt
│   └── k8s-pods.txt
├── default
│   ├── k8s-acrolinx-core-server-0-logs.previous.txt
│   ├── k8s-acrolinx-core-server-0-logs.txt
│   ├── k8s-acrolinx-friendly-error-pages-7574cd4769-b5zqw-logs.previous.txt
│   ├── k8s-acrolinx-friendly-error-pages-7574cd4769-b5zqw-logs.txt
│   ├── k8s-acrolinx-friendly-error-pages-7574cd4769-lggt4-logs.previous.txt
│   ├── k8s-acrolinx-friendly-error-pages-7574cd4769-lggt4-logs.txt
│   ├── k8s-acrolinx-image-detail-fetcher-1616142600-zbd5m-logs.previous.txt
│   ├── k8s-acrolinx-image-detail-fetcher-1616142600-zbd5m-logs.txt
│   ├── k8s-acrolinx-language-server-6844598b44-cts4l-logs.previous.txt
│   ├── k8s-acrolinx-language-server-6844598b44-cts4l-logs.txt
│   ├── k8s-acrolinx-target-service-5448dd67f9-f8bfg-logs.previous.txt
│   ├── k8s-acrolinx-target-service-5448dd67f9-f8bfg-logs.txt
│   ├── k8s-all.txt
│   ├── k8s-coreplatforms.txt
│   ├── k8s-deployments.txt
│   ├── k8s-events.txt
│   ├── k8s-impfo-config-maps.txt
│   ├── k8s-other-logs.txt
│   └── k8s-pods.txt
├── default-namespace.txt
├── kube-system
│   ├── k8s-all.txt
│   ├── k8s-deployments.txt
│   ├── k8s-other-logs.txt
│   └── k8s-pods.txt
├── olm
│   ├── k8s-all.txt
│   ├── k8s-deployments.txt
│   ├── k8s-other-logs.txt
│   └── k8s-pods.txt
├── operators
│   ├── k8s-all.txt
│   ├── k8s-deployments.txt
│   ├── k8s-other-logs.txt
│   └── k8s-pods.txt
└── snapshot_time.txt
```

**Note**: *All the captured data is written in plain text and can be reviewed anytime in the archive.*
## Check the Deployment Manually (Using `kubectl`)

**Note:** *Basic Kubernetes knowledge is suggested.*

Use the kubectl commands in the sections below as a quick reference when working with Kubernetes.

Most recent Kubernetes resource types:
- Namespaces: `namespaces`
- ConfigMaps: `configmaps`
- Secrets: `secrets`
- Events: `events`
- Deployments: `deployments`
- Services: `services`
- Pods: `pods`
- Endpoints: `endpoints`
- Ingresses: `ingresses`
- PersistentVolumes: `persistentvolumes`
- PersistentVolumeClaims: `persistentvolumeclaims`

Acrolinx custom resource definitions:
- CorePlatform: `coreplatform`

**Note:** *This isn’t a full list.*

### Listing Resources

To list existing Kubernetes resources use the `kubectl get [resource-type]` command.

To list all resources use:

```
$ kubectl get all
```

**Note:** *Use `watch` to keep it listing interactively. Example: `watch kubectl get all`*

#### Hint: Listing Cluster Events
In most cases when you need to debug something it can be a good starting point to list all events in your cluster.

To list all events:
```
$ kubectl get events
```

**Note:** *Events are deleted after a short time. So it can happen that this command returns with message "No resources found ...". In this case try restarting your server or the Kubernetes distribution and list events on startup.*

### Displaying Resource State

To display the state of any number of resources in detail:
```
$ kubcetl describe [resource-type] [name]
```
Examples:

Show details about all pods:
```
$ kubectl describe pods
```
Show detail about one particular pod:
```
$ kubectl describe pods [pod-name]
```

#### Hint: Get Details of the CorePlatform
To check its status and configuration of the deployed Acrolinx instance use the command:
```
$ kubectl describe coreplatform
```

**Note:** *Under `Spec:` you should see the configuration details and the installed GuidancePackage.*

**Note:** *Under `Status:` and `Images:` you should see the deployed images. Check the image label `com.acrolinx.buildversion` to verify the installed Acrolinx version.*

### Printing Container Logs
To print logs from containers in a pod, use the kubectl logs command.

```
$ kubectl logs [pod-name]
```

**Note:** *To stream logs from a pod, use the `-f` switch. Example: `kubectl logs -f [pod-name]`*

## Deploy the Kubernetes Dashboard

**Note:** *Supposed that you’re using K3s as the Kubernetes distribution that is recommended to operate Acrolinx.*

**Note:** *Basic Kubernetes knowledge is suggested.*

To get a visual overview of your Kubernetes cluster state there’s a web UI that can be deployed as an individual service.
Using the Kubernetes dashboard can help you check the existing resources in your cluster and edit configurations. Further more the UI shows the CPU and Memory utilization and even can help to notice errors quicker. 

See more about how to deploy the Kuberneted Dashboard: https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

**Note:** *The Dashboard has built in role-based access control and authentication required to get access to its functions.*

**Disclaimer:** *Do NOT publicly expose your Kubernetes Dashboard UI! People with access can apply changes or delete existing resources via the Dashboard that can be harmful!*
