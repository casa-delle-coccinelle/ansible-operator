
# Description
Helm chart which installs ansible-operator app in Kubernetes cluster.
# Variables
| Variable | Description | Default | Required | 
|--|--|--|--|
| replicaCount | Number of pods in the repliceset. | 1 | No |
| image.repository | Image repo | c-harbor.casa-delle-coccinelle.link/operator/ansible-operator | No |
| image.pullPolicy | Image pull policy | IfNotPresent | No |
| image.tag | Image tag | v0.1.0 | No |
| imagePullSecrets | Image pull secrets | [] | No |
| nameOverride | name override | "" | No |
| fullnameOverride | full name override | "" | No |
| serviceAccount.annotations | Service account annotations | [] | No |
| serviceAccount.name | Service account name. Name will be generated if not specified. | "" | No |
| chartWideAnnotations | Annotations to be added to all resources in the chart | | No |
| managerArgs | Additional arguments to be passed to the operator. The chart sets --health-probe-bind-address, --metrics-bind-address (if metrics.enabled is set to true), --leader-elect and --leader-election-id | | No |
| managerEnv | List of environment variables to be exposed to the operator | - name: ANSIBLE_GATHERING<br> value: explicit | No |
| healthProbeBindAddress | Health probe bind port | 6789 | No |
| probes.liveness.enabled | Enable liveness probe | true | No |
| probes.liveness.initialDelaySeconds | Initial delay for liveness probe in seconds | 15 | No |
| probes.liveness.periodSeconds | Liveness probe period in seconds | 20 | No |
| probes.readiness.enabled | Enable readiness probe | true | No |
| probes.readiness.initialDelaySeconds | Initial delay for readiness probe in seconds | 5 | No |
| probes.readiness.periodSeconds | Readiness probe period in seconds | 10 | No |
| securityContext | Security context for manager container | allowPrivilegeEscalation: false<br>capabilities:<br>&nbsp;&nbsp;drop:<br>&nbsp;&nbsp;- ALL | No |
| resources | Container resources | limits:<br>&nbsp;&nbsp;cpu: 500m<br>&nbsp;&nbsp;memory: 768Mi<br>requests:<br>&nbsp;&nbsp;cpu: 10m<br>&nbsp;&nbsp;memory: 256Mi | No |
| podAnnotations | k8s annotations to be added to the pods |{} | No |
| podSecurityContext | Pod security context | {} | No |
| securityContext | Container security context | {} | No |
| nodeSelector | Node selector | {} | No |
| tolerations | Tolerations | [] | No |
| affinity | Affinity | {} | No |

# Installation
Install/update the chart with the following command

    helm  upgrade --reset-values --install --create-namespace --namespace "${NAMESPACE}" ${RELEASE_NAME} ansible-operator/ -f /path/to/your_values.yaml

