## AnsibleJobSpec
### roles ([]object)
List of ansible galaxy roles, needed by the playbook
- **roles.name**, required - name of ansible galaxy role
- **roles.src**, required - source of ansible galaxy role
- **roles.version** - version of ansible galaxy role
### collections ([]object)
List of ansible collections, needed by the playbook
- **collections.name**, required - name of ansible collection
- **collections.version** - version of ansible collection
### vault_password (string)
Ansible vault password. The operator will create Kubernetes secret with the password and mount it in executor's container.
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
- **inventory.configMapRef.name** - Name of Kubernetes configmap holding ansible inventory to the supplied to ansible playbook
- **inventory.secretRef.name** - Name of Kubernetes secret holding ansible inventory to the supplied to ansible playbook
### playbook (object), required
Ansible playbook to be executed. Currently the operator accepts playbooks defined as Kubernetes secret or configmap, as well as located in a git repository.
##### Git
- **playbook.git.repo**, required - Git repository URL
- **playbook.git.repo_path** - Git repository path to the playbook, relative to the repository root. If not defined, the executor will looks for **playbook.git.playbook_name** in repository's root
- **playbook.git.repo_branch** - Git repository branch, defaults to master
- **playbook.git.playbook_name** - Ansible playbook file name, defaults to **playbook.yaml**
- **playbook.git.requirements_name** - Ansible requirements file, defaults to **requirements.yaml**. If *roles* and *collections* properties are set, the executor will install them as well.
##### Secret
- **playbook.secretRef.name** - Name of Kubernetes secret holding ansible playbook
##### Configmap
- **playbook.configMapRef.name** - Name of Kubernetes configmap holding ansible playbook

At least one of playbook.git, playbook.secretRef and playbook.configMapRef must be defined.
### additional_vars ([]object)
List with additional variables to be provided to the playbook
- **additional_vars.name** - Variable name
- **additional_vars.value** - Variable value. Numeric and boolean values should be quoted in order to pass validation
- **additional_vars.secretRef.name** - Name of Kubernetes secret holding ansible style variables
- **additional_vars.configMapRef.name** - Name of Kubernetes configmap holding ansible style variables
All defined variables will be supplied to the playbook.
### additional_ansible_options ([]string)
List of additional ansible playbook options (e.g. "--force-handlers"). The options will be supplied as defined without any verification.
### additional_env ([]object)
List of environment variables to be exposed in executor's container
- **additional_env.name** - Variable name
- **additional_env.value** - Variable value. Numeric and boolean values should be quoted in order to pass validation
### job_backoffLimit
Backoff limit to be set on executor pod
### job_restartPolicy
Pod restart policy for the executor pod.

## AnsibleCronSpec
Supports ALL AnsibleJobSpec properties and
### schedule (string)
Schedule for the Kubernetes cronjob
