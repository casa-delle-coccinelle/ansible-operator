
# Description
Helm chart which installs ansible-operator app in Kubernetes cluster.
# Variables
| Variable | Description | Default | Required | Versions | 
|--|--|--|--|--|
| replicaCount | Number of pods in the repliceset. | 1 | No | 0.1.0 |
| image.repository | Image repo | c-harbor.casa-delle-coccinelle.link/operator/ansible-operator | No | 0.1.0 |
| image.pullPolicy | Image pull policy | IfNotPresent | No | 0.1.0 |
| image.tag | Image tag | v0.1.0 | No | 0.1.0 |
| imagePullSecrets | Image pull secrets | [] | No | 0.1.0 |
| nameOverride | name override | "" | No | 0.1.0 |
| fullnameOverride | full name override | "" | No | 0.1.0 |
| serviceAccount.annotations | Service account annotations | [] | No | 0.1.0 |
| serviceAccount.name | Service account name. Name will be generated if not specified. | "" | No | 0.1.0 |
| chartWideAnnotations | Annotations to be added to all resources in the chart | | No | 0.1.0 |
| managerArgs | Additional arguments to be passed to the operator. The chart sets --health-probe-bind-address, --metrics-bind-address (if metrics.enabled is set to true), --leader-elect and --leader-election-id | | No | 0.1.0 |
| managerEnv | List of environment variables to be exposed to the operator | - name: ANSIBLE_GATHERING<br> value: explicit | No | 0.1.0 |
| healthProbeBindAddress | Health probe bind port | 6789 | No | 0.1.0 |
| probes.liveness.enabled | Enable liveness probe | true | No | 0.1.0 |
| probes.liveness.initialDelaySeconds | Initial delay for liveness probe in seconds | 15 | No | 0.1.0 |
| probes.liveness.periodSeconds | Liveness probe period in seconds | 20 | No | 0.1.0 |
| probes.readiness.enabled | Enable readiness probe | true | No | 0.1.0 |
| probes.readiness.initialDelaySeconds | Initial delay for readiness probe in seconds | 5 | No | 0.1.0 |
| probes.readiness.periodSeconds | Readiness probe period in seconds | 10 | No | 0.1.0 |
| securityContext | Security context for manager container | allowPrivilegeEscalation: false<br>capabilities:<br>&nbsp;&nbsp;drop:<br>&nbsp;&nbsp;- ALL | No | 0.1.0 |
| resources | Container resources | limits:<br>&nbsp;&nbsp;cpu: 500m<br>&nbsp;&nbsp;memory: 768Mi<br>requests:<br>&nbsp;&nbsp;cpu: 10m<br>&nbsp;&nbsp;memory: 256Mi | No | 0.1.0 |
| podAnnotations | k8s annotations to be added to the pods |{} | No | 0.1.0 |
| podSecurityContext | Pod security context | {} | No | 0.1.0 |
| securityContext | Container security context | {} | No | 0.1.0 |
| nodeSelector | Node selector | {} | No | 0.1.0 |
| tolerations | Tolerations | [] | No | 0.1.0 |
| affinity | Affinity | {} | No | 0.1.0 |

# Installation
Install/update the chart with the following command

    helm  upgrade --reset-values --install --create-namespace --namespace "${NAMESPACE}" ${RELEASE_NAME} ansible-operator/ -f /path/to/your_values.yaml

