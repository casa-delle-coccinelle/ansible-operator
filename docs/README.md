
### ansible-operator
Operator for managing execution of ansible playbooks as cronjobs and jobs in a Kubernetes cluster. Once installed, it will watch all namespaces for resources of type ansiblejobs and ansiblecrons. For each resource type it will create Kubernetes job or cronjob to run the ansible executor pod.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./images/overview-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="./images/overview-light.png">
  <img alt="Switch image." src="./images/overview-light.png">
</picture>

### Installation
To install the operator to your Kubernetes cluster you should have helm installed.

    git clone https://github.com/casa-delle-coccinelle/ansible-operator.git
    cd ansible-operator/
    make deploy
This will apply CRD manifests to the Kubernetes cluster configured in ~/.kube/config and install the operator [helm chart](../helm_chart/ansible-operator) in *ansible-operator* namespace, using *ansible-operator* as helm release name
To clear all resources use:

    make undeploy
This will delete the CRDs and namespace and uninstall the helm release from the Kubernetes cluster configured in ~/.kube/config

### Documentation
* [Custom resource definitions](./CRDS.md)
* [ansible-executor ansible role](./ANSIBLE_EXECUTOR.md)
* [ansible-operator helm chart](./HELM_CHART.md)
* [Makefile](./MAKEFILE.md)
