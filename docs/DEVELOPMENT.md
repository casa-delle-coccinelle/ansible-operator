### Builds
Two workflows are created to build and push operator and executor images.
#### Dev
The names of the branches with new versions of ansible operator should start with the letter "v" followed by version number MAJOR.MINOR.PATCH (https://semver.org/). For example, if the current version of the operator is v0.1.0 and bug fix is needed, the branch with the fix should be named "v0.1.1". Docker images built from this branch will be tagged "v0.1.1.dev"
#### Release
Docker images with released version are built only if tag with the corresponding version is pushed after merge to master. Tags should start with the letter "v" followed by version number MAJOR.MINOR.PATCH (https://semver.org/). For example, if tag v0.1.1 is pushed, docker image with tag "v0.1.1" will be built.

### [Makefile](../Makefile)
#### Vars
| Variable | Description | Default |
|--|--|--|
| VERSION | Docker images tag  | v0.1.0 |
| OPERATOR_IMAGE_TAG_BASE | Docker image registry for operator image  | internal registry |
| EXECUTOR_IMAGE_TAG_BASE | Docker image registry for executor image  | internal registry |
| HELM_VALUES_PATH | Path to custom helm value file  | helm_chart/ansible-operator/values.yaml |
| NAMESPACE | Namespace for operator's helm release  | ansible-operator |
| RELEASE_NAME | operator's helm release name  | ansible-operator |
| OPERATOR_DOCKERFILE | Path to operator's docker file  | docker/Dockerfile |
| EXECUTOR_DOCKERFILE | Path to executor's docker file  | docker/Dockerfile_ansible_executor |
#### Usage
##### Build

    make docker-build docker-push 

##### Deploy

    make deploy

Will install CRDs and operator

##### Clean-up

    make undeploy

Will delete CRDs, operator relese and namespace
### executor_start.sh
