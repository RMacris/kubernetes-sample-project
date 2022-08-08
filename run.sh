#!/bin/sh

# 0.ensures clusters don't exists before creating
kubectl delete pvc --all # delete all claimers to any persistent volume
kubectl delete pv --all  #delete all persistenVolume
kind delete cluster --name=rafael-cluster-nginx-webserver


# 1.create kind cluster
kind create cluster --config=./cloud/kindClusterDeployConfig.yaml

# 2.kubectl create namespace
kubectl apply -f ./cloud/namespace.yaml

# 3.create config map that will be used from the pod as environment variable 
# must exist before pod be created 
kubectl apply -f ./cloud/configMaps/basic-config.yaml

# 4.Since Secrets are a superset of ConfigMaps, it is a good approuch to create then in the namespace before
# the pod is mounted
kubectl apply -f ./Secrets/secret.yaml
#? ################### ?#
#?    SealedSecrets    ?#
#? ################### ?#

#? Require https://github.com/bitnami-labs/sealed-secrets
# in order to create SealedSecret you have to pipe a normal secret creation into a 
# "Kubeseal" command is the client part of SealedSecrets that creates the encryption
# in order for your cluster to be able to decript the secret you must apply the
# controller.yaml definition by bitnami into your cluster by doing:

kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.1/controller.yaml

# once it's done you can create the secret secret by doing:
#? reference https://www.eksworkshop.com/beginner/200_secrets/installing-sealed-secrets/
# # kubectl --namespace <namespace> create secret genetic <secret_name> --from-literal=<key>=<value> -o json --dry-run=client | kubeseal -o yaml > <yaml_path>
kubectl --namespace rafael-test-namespace create secret generic sealed-test --from-literal=food=banana -o json --dry-run=client | kubeseal -o yaml > ./SealedSecrets/SealedSecret.yaml

#that command will encrypt the secret and find the namespace you want to create the SealedSecret, 
#atatch to already created yaml file as SealedSecret manifest with the value encrypted
#to deploy in the cluster as a normal unnecrypted secret you must do: 
kubectl apply -f ./SealedSecrets/SealedSecret.yaml
#as a normal secret it must be created before the any deployment to want to use it 


#create the service to expose the pod
kubectl apply -f ./cloud/service/container-exposer-service.yaml

#create the voluem 
kubectl apply -f ./cloud/volumes/persistent-filesystem-volume.yaml
# create the claimer to that volume

kubectl apply -f ./cloud/volumes/persistent-volume-claim.yaml

# create a pod that uses all the especifications above
kubectl apply -f ./cloud/deploy.yaml --context kind-rafael-cluster-nginx-webserver

