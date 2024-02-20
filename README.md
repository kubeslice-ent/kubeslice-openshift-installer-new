# kubeslice-openshift-installer
kubeslice-openshift-installer: Repository containing the scripts used for installing/upgrading/managing at scale

# Demo installer with ansible 
# Prerequisites

To Run the Above installation script you need to install some packages
- Ansible 
- Helm 
- Kubectx
- Kubectl 

(If your using Openshift cluster then below command line tool also)
- oc 

# Labeling Nodes 

If you have multiple node pools on your cluster, then you can add a label to each node pool. Labels are useful in managing scheduling rules for nodes.

**Perform these steps on all your clusters to label the worker node:**
 
```
kubectl get nodes
```
 Run the following command to label your node:

```
kubectl label node <node name> kubeslice.io/node-type=gateway
```

# To Start the installation follow below steps
```
git clone https://github.com/kubeslice/kubeslice-hyperscaler.git
```

After cloning repo use below commands to install all the requirments 

```bash
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install cloud.common
pip3 install -r requirements.txt --user  
```
To Run the installtion script you need to pass some values to the script in "vars/install-vars.yaml" file 

```
vars/install-vars.yaml
```
```
### Helm charts details ###
helm_repo_name: <Repo-name> 
helm_chart_url: <Helm-chart-url>

### IMP Note - If Your providing enterprise helm chart url then you must need to provide your username and password to create a Imagepullsecret to pull the enterpise images###
# If your providing Opensource helm chart Url no need to worry about the username and password
docker_username: username
docker_password: password

### Required cluster details ###
#Note- If you have multiple worker clusters you can add your worker cluster details in below format ##

clusters:
  controller:
    kubeconfig: ./path_of_kubeconfig/
    projectNamespace: avesha  
    openshift_cluster: false
    chart_version:                #If you keep that value null it will take the latest chart version    
    endpoint:                     #If you keep that value null it will fetch default endpoint from cluster
    image:                        #If null it will take the latest values
    tag:                          #If null it will take the latest values
    Kubeslice_ui:
      chart_version:              #If you keep that value null it will take the latest chart version
      service_type:               #If null it will take "Loadbalancer" as a default value
      image:                      #If null it will take the latest values
      tag:                        #If null it will take the latest values

  worker:
  - name: worker-1
    kubeconfig: /path_of_kubeconfig/
    openshift_cluster: false
    chart_version:              #If you keep that value null it will take the latest chart version
    nodeIp:                     #If you are using cloud clusters no need to provide worker NodeIP only provide NodeIP in Kind and DC clusters
    endpoint:                   #Default value is Null
    networkInterface:           #Default value is eth0
    metrics_insecure:           #Default value is false
    operator:
      image:                    #If null it will take the latest values
      tag:                      #If null it will take the latest values

  - name: worker-2
    kubeconfig: /path_of_kubeconfig/
    openshift_cluster: false
    chart_version:              #If you keep that value null it will take the latest chart version
    nodeIp:                     #If you are using cloud clusters no need to provide worker NodeIP only provide NodeIP in Kind and DC clusters
    endpoint:                   #Default value is Null
    networkInterface:           #Default value is eth0
    metrics_insecure:           #Default value is false
    operator:
      image:                    #If null it will take the latest values
      tag:                      #If null it will take the latest values

slices:
  - name: iperf-slice
    workerClusters:
      - worker-1
      - worker-2
    sliceSubnet: 192.168.0.0/16
    sliceGatewayServiceType:  
      # - cluster: worker-1
      #   type: LoadBalancer   
      #   protocol: TCP  
    priority: 3 
    bandwidthCeilingKbps: 20480
    bandwidthGuaranteedKbps: 10240
    applicationNamespaces:
    - namespace: iperf
      clusters:
      - worker-1
      - worker-2    
    externalGatewayConfig:       # If you dont want to deploy slice with externalGatewayConfig keep this value blank 

  - name: boutique-slice
    workerClusters:
      - worker-1
      - worker-2
    sliceSubnet: 192.168.0.0/16
    sliceGatewayServiceType: 
      # - cluster: worker-1
      #   type: LoadBalancer   
      #   protocol: TCP      
    priority: 3 
    bandwidthCeilingKbps: 20480
    bandwidthGuaranteedKbps: 10240
    applicationNamespaces:
    - namespace: boutique
      clusters:
      - worker-1
      - worker-2    
    externalGatewayConfig:       # If you dont want to deploy slice with externalGatewayConfig keep this value blank


## Application Deployment and Service_Export creation ##
onboardAppsToSlices:
  iperfDeployment:
    - name: worker-1
      iperfClient: true       #iperf-sleep
      iperfServer: false      #iperf-server
      applicationNs: iperf
    - name: worker-2
      iperfClient: false      #iperf-sleep
      iperfServer: true       #iperf-server
      applicationNs: iperf

  boutiqueDeployment:
    - name: worker-1
      boutiqueClient: false       #boutique-frontendServices, productcatalogService, recommendationService, shippingService
      boutiqueServer: true     #boutique-adService,currencyService,emailService,paymentService
      applicationNs: boutique
    - name: worker-2
      boutiqueClient: true     #boutique-frontendServices, productcatalogService, recommendationService, shippingService
      boutiqueServer: false      #boutique-adService,currencyService,emailService,paymentService
      applicationNs: boutique

### Service_Export ###
serviceExport:
  - name: iperf-server         #Iperf-application serviceexport
    workerName: worker-2        
    sliceName: iperf-slice
    applicationNs: iperf
    ingressEnabled: false
    ports:
    - name: tcp
      containerPort: 5201
      protocol: TCP
    labels:
      app: iperf-server

  - name: ad-service           #boutique-application serviceexport
    workerName: worker-1
    sliceName: boutique-slice
    applicationNs: boutique
    ingressEnabled: false
    ports:
    - name: http
      containerPort: 9555
      protocol: TCP
    labels:
      app: adservice
      name: kubeslice-demo

  - name: currency-service     #boutique-application serviceexport
    workerName: worker-1
    sliceName: boutique-slice
    applicationNs: boutique
    ingressEnabled: false
    ports:
    - name: http
      containerPort: 7000
      protocol: TCP
    labels:
      app: currencyservice
      name: kubeslice-demo

  - name: payment-service       #boutique-application serviceexport
    workerName: worker-1
    sliceName: boutique-slice
    applicationNs: boutique
    ingressEnabled: false
    ports:
    - name: http
      containerPort: 50051
      protocol: TCP
    labels:
      app: paymentservice
      name: kubeslice-demo

  - name: email-service        #boutique-application serviceexport
    workerName: worker-1
    sliceName: boutique-slice
    applicationNs: boutique
    ingressEnabled: false
    ports:
    - name: http
      containerPort: 5000
      protocol: TCP
    labels:
      app: emailservice
      name: kubeslice-demo    

  - name: recommendation-service       #boutique-application serviceexport
    workerName: worker-2
    sliceName: boutique-slice
    applicationNs: boutique
    ingressEnabled: false
    ports:
    - name: http
      containerPort: 8080
      protocol: TCP
    labels:
      app: recommendationservice
      name: kubeslice-demo

  - name: shipping-service       #boutique-application serviceexport
    workerName: worker-2
    sliceName: boutique-slice
    applicationNs: boutique
    ingressEnabled: false
    ports:
    - name: http
      containerPort: 50051
      protocol: TCP
    labels:
      app: shippingservice
      name: kubeslice-demo

  - name: productcatalog-service       #boutique-application serviceexport
    workerName: worker-2
    sliceName: boutique-slice
    applicationNs: boutique
    ingressEnabled: false
    ports:
    - name: http
      containerPort: 3550
      protocol: TCP
    labels:
      app: productcatalogservice
      name: kubeslice-demo

### Monitoring clusters  ###
monitoring_cluster:
  elasticsearch:
  - name: worker-1-elasticsearch
    workerName: worker-1
    storage_size: 30Gi
    nodePort: 32000 
    replicas: 2

  fluent_bit:
  - name: worker-1-fluent-bit
    workerName: worker-2
    elasticsearch_name: worker-1-elasticsearch
    elasticsearch_nodeIP: <elastic-search-nodeIP>         #elasticsearch-nodeIP
    elasticsearch_port: 32000
  
  kibana:
  - name: worker-1-kibana
    workerName: worker-2
    service_type: NodePort                 
    elasticsearch_name: worker-1-elasticsearch
    elasticsearchURL: "http://<elasticsearch-nodeIP>:<elasticsearch-nodeport>"

........
```
After providing all the required values in the file you can review your installation file (roles) and start the installation 
 
```
---
- name: Installation playbook
  hosts: localhost
  connection: local
  vars_files:
    - vars/install-vars.yaml

  roles:
###### input file validation check ######  
     - pre-validation-check                #It will perform some pre-validation checks on you all-var input file#

###### Helm Access ######
     - helm-repo-access                    # It will Add helm chart repo in your local

####### Opensource Charts ######           # If you are using opensource charts comment out below enterprise roles #
     # - kubeslice-controller-oss              # This will deploy Controller and create project        
     # - worker-registration-oss               # This will register workercluster with controller and genrate worker-secret file 
     # - kubeslice-worker-oss                  # This will deploy istio,Isitod and Worker-operator Charts
     # - openshift-deployement-patch         # This is patching for openshif related clusters
     
##### Enterprise Charts ######          # If you are using enterprise charts comment out above Opensource roles #
     - kubeslice-controller-ent             # This will deploy Controller with UI and create project        
     - worker-registration-ent              # This will register workercluster with controller and genrate worker-secret file 
     - kubeslice-worker-ent                 # This will deploy istio,Isitod,prometheus and Worker-operator Charts
     - openshift-deployement-patch          # This is patching for openshift related clusters

###### Slice-config and App deployment ######    
     - slice-config-installation            # It will Create Sliceconfig only
     - onboarding-demo-application          # It will cover Application deployment (iperf,bookinfo,Obs,boutique,cockroach-db) 
     - service-export-creation              # It will create serviceexport 
     # - custom-application-deployment      # It will cover Custom Application deployemt using manifest file or helm chart deployement
     # - bookinfo-load-generator            # It will use to generate load on bookinfo application 
     
#######  Logs and Monitoring #######
     - kubeslice-diagnosis                  #It will capturing Log for debugging
     # - kubeslice-monitoring               #It will deploy elasticsearch , fluent-bit , Kibana and prometheus on your defined cluster

####### Kafka-zookeeper clusters ######
     # - kafka-zookeeper-setup             #It will deploy kafka and zookeeper on all worker clusters             # Kubecost provides real-time cost visibility and insights for teams using Kubernetes

###### Output Summary ######
     - kubeslice-status-report              # This will generate Kubeslice output status summary and display on terminal


```
In above file if you dont want to use any particuler role then you can comment out that role 

---
**NOTE**
If you are using **openshift** cluster in your setup make sure you enabled **openshift_cluster: true** flag in **install-vars.yaml** file before running below playbook
---


```
ansible-playbook installation.yaml
```


# Uninstalling kubeslice 

For uninstallation purpose we have to maintain different var file " vars/destroy-vars.yaml " , put existing cluster values in destroy-var.yaml then run destory.yaml playbook to uninstall the setup

If you want to destroy whole existing environment use below playbook 

```
ansible-playbook  destroy.yaml
```

We have enabled tags in destroy.yaml playbook , if we want to destory specific task you can do that
we have below tags

- serviceexport -> it will delete the serviceexport from the cluster
- iperf,bookinfo,obs,boutique,cockroachDB -> it will delete the demo application 
- customapp -> it will delete the custom deployed application
- sliceconfig -> it will offboard namespaces from slices and delete sliceconfig
- istio -> it will uninstall istio charts
- kubeslice-worker -> it will uninstall the kubeslice-worker charts from worker cluster
- worker-registertion -> it will deregistring worker cluster with controller
- project -> deleting a Project namespace
- kubeslice-ui -> it will uninstall kubeslice-UI charts
- kubeslice-controller -> it will uninstall kubeslice-controller charts
- cert-manager -> it will uninstall cert-manager charts
- controller-crd  -> it will delete all the crd related to controller cluster
- worker-crd  -> it will delete all the crd related to worker cluster

---
** IMP NOTE**

Uninstalltion is a critical task so choose your tags carefully

---

Example - If you want to destory only istio charts use belowcommand 
```
ansible-playbook destroy.yaml --tags istio 

