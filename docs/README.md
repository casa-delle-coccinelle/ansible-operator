## AnsibleJobSpec

### roles ([]object)
List of ansible galaxy roles, needed by the playbook
- **roles.name**, required - name of ansible galaxy role
- **roles.src**, required - source of ansible galaxy role
- **roles.version** - version of ansible galaxy role
### collections ([]object)
List of ansible collections, needed by the playbook
- collections.name, required - name of ansible collection
- collections.version - version of ansible collection
### vault_password (string)
Ansible vault password
### vault_password_secret (object)
Kubernetes secret holding ansible vault password
- **vault_password_secret.secretRef.name**, required - Name of the kubernetes secret holding ansible vault password. It will be mounted on the pod and supplied with --vault-password-file to the playbook
### ssh_keys ([]object)
List of SSH keys and SSH client configuration needed ansible to establish connection to the target hosts or to pull necessary repositories
- **ssh_keys.name**, required - Name of the key
- **ssh_keys.secretRef.name**, required - Name of Kubernetes secret, holding "ssh-privatekey" and "ssh-publickey" SSH key data. (reference - https://kubernetes.io/docs/concepts/configuration/secret/#use-case-pod-with-ssh-keys)
- **ssh_keys.config.configMapRef.name** - Name of Kubernetes configmap, holding SSH client configuration for the SSH key
- **ssh_keys.config.secretRef.name** - Name of Kubernetes secret, holding SSH client configuration for the SSH key
### inventory ([]object)
- inventory.configMapRef.name - Name of Kubernetes configmap holding ansible inventory to the supplied to ansible playbook
- inventory.secretRef.name - Name of Kubernetes secret holding ansible inventory to the supplied to ansible playbook
### playbook (object), required
