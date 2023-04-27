# Set the default compute region
gcloud config set compute/region us-central1

# Set the default compute zone
gcloud config set compute/zone us-central1-a



gke_name="my-dummy-cluster"

# Create a cluster
gcloud container clusters create --machine-type=e2-medium ${gke_name} 

# Authenticate with the cluster
gcloud container clusters get-credentials ${gke_name} 

# GKE uses Kubernetes objects to create and manage your cluster's resources. 
# Kubernetes provides the Deployment object for deploying stateless applications like web servers. 
# Service objects define rules and load balancing for accessing your application from the interne
# create a new Deployment
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:2.0

# create a Kubernetes Service, which is a Kubernetes resource that lets you expose your application to external traffic
kubectl expose deployment hello-server --type=LoadBalancer --port 8082

kubectl get service
# http://146.148.77.159:8082

# delete the cluster
gcloud container clusters delete ${gke_name} 

#------------------------------------------------------------
# Install nginx on vm
#------------------------------------------------------------
sudo apt-get update
sudo apt-get install -y nginx
ps auwx | grep nginx
# http://EXTERNAL_IP/

#------------------------------------------------------------
# Create multiple web server instances
#------------------------------------------------------------
# virtual machine www1
  gcloud compute instances create www1 \
    --zone=us-east4-c \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#! /bin/bash
sudo apt-get update
sudo apt-get install -y nginx
sudo sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
sudo service nginx start'

# virtual machine www2
  gcloud compute instances create www2 \
    --zone=us-east4-c \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "<h3>Web Server: www2</h3>" | tee /var/www/html/index.nginx-debian.html'

# virtual machine www3
  gcloud compute instances create xyz \
    --zone=us-east4-c \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "
<h3>Web Server: www3</h3>" | tee /var/www/html/index.html'

# firewall rule to allow external traffic to the VM instances
gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80

gcloud compute instances list
# curl http://[IP_ADDRESS]

#------------------------------------------------------------
#Configure the load balancing service
#------------------------------------------------------------
# static external IP
   gcloud compute addresses create network-lb-ip-1 \
    --region us-east4 

# legacy HTTP health check
gcloud compute http-health-checks create basic-check

# Add a target pool in the same region as your instances
  gcloud compute target-pools create www-pool \
    --region us-east4 --http-health-check basic-check


# Add the instances to the pool
gcloud compute target-pools add-instances www-pool \
    --instances www1,www2,www3

# forwarding rule
gcloud compute forwarding-rules create www-rule \
    --region  us-east4 \
    --ports 80 \
    --address network-lb-ip-1 \
    --target-pool www-pool

#------------------------------------------------------------
# Sending traffic to your instances
#------------------------------------------------------------

# view the external IP address of the www-rule forwarding rule used by the load balancer
gcloud compute forwarding-rules describe www-rule --region us-east4

# ccess the external IP address
IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region us-east4 --format="json" | jq -r .IPAddress)

echo $IPADDRESS

while true; do curl -m1 $IPADDRESS; done

#------------------------------------------------------------
# Create an HTTP load balancer
#------------------------------------------------------------

# Set the default compute region
gcloud config set compute/region us-east4

# Set the default compute zone
gcloud config set compute/zone us-east4-c

gcloud compute instance-templates create lb-backend-template \
   --region=us-east4 \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-11 \
   --image-project=debian-cloud \
   --metadata=startup-script='#! /bin/bash
sudo apt-get update
sudo apt-get install -y nginx
sudo service nginx start'

gcloud compute instance-groups managed create lb-backend-group \
   --template=lb-backend-template --size=2 --zone=us-east4-c 


gcloud compute firewall-rules create allow-tcp-rule-551 \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global

gcloud compute health-checks create http http-basic-check \
  --port 80

gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=us-east4-c \
  --global

gcloud compute url-maps create web-map-http \
    --default-service web-backend-service

gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http

gcloud compute forwarding-rules create http-content-rule \
    --address=lb-ipv4-1\
    --global \
    --target-http-proxy=http-lb-proxy \
    --ports=80