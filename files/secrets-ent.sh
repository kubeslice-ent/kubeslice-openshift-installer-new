# The script returns a kubeconfig for the service account given
# you need to have kubectl on PATH with the context set to the cluster you want to create the config for

# Cosmetics for the created config
firstSpokeSecretName=$1

clusterName=$2
# the Namespace and ServiceAccount name that is used for the config
namespace=$3

kubeconfig=$4

######################
# actual script starts
set -o errexit

### First Spoke cluster Secrets ###
PROJECT_NAMESPACE=$(kubectl get secrets $firstSpokeSecretName -n $namespace  -o jsonpath={.data.namespace} --kubeconfig=$kubeconfig)
CONTROLLER_ENDPOINT=$(kubectl get secrets $firstSpokeSecretName -n $namespace  -o jsonpath={.data.controllerEndpoint} --kubeconfig=$kubeconfig)
CA_CRT=$(kubectl get secrets $firstSpokeSecretName -n $namespace  -o jsonpath='{.data.ca\.crt}' --kubeconfig=$kubeconfig)
TOKEN=$(kubectl get secrets $firstSpokeSecretName -n $namespace  -o jsonpath={.data.token} --kubeconfig=$kubeconfig)

echo "
---
## Base64 encoded secret values from controller cluster
controllerSecret:
  namespace: ${PROJECT_NAMESPACE}
  endpoint: ${CONTROLLER_ENDPOINT}
  ca.crt: ${CA_CRT}
  token: ${TOKEN}

cluster:
  name: ${clusterName}
  
"
