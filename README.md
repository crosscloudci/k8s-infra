# k8s-infra


# Quick start
You'll need a set of ip addresses to create the K8s cluster.

#### Build the prerequisites
```
   docker build -t crosscloudci/k8s-infra-deps:latest --file Dockerfile.deps .
```
#### Build the Docker container
```
  docker build -t crosscloudci/k8s-infra:latest . 
```

#### Generate the kube-spray configuration file and provision the K8s cluster

*Note: You must have either 3 or more masters.  It doesn't matter how many workers you have.*
```
docker run -v $(pwd):/k8s-infra:latest -v -ti kubespray /bin/bash 
./k8s-infra/bin/k8sinfra generate_config --release-type=stable --master-hosts "<your-ip-address>,<your-ip-address>,<your-ip-address>" --worker-hosts "<your-ip-address>,<your-ip-address>,<your-ip-address>" -o /tmp/test.yml; \
./k8sinfra provision --config-file '/tmp/test.yml'"  
```
Save the resulting kubeconfig file to your local development machine

# Useful Developer Dommands 

### Build deps for k8s-infra 

```
   docker build -t crosscloudci/k8s-infra-deps:latest --file Dockerfile.deps .
```

### Build k8s-infra
```
  docker build -t crosscloudci/k8s-infra:latest . 
```

### Optional: Push to dockerhub repository
```
   docker push crosscloudci/k8s-infra-deps:latest
```

### Optional: push of k8s-infra docker image
```
   docker push crosscloudci/k8s-infra:latest
```

### Test the docker image
```
   docker run -ti crosscloudci/k8s-infra:latest
```
### Test with port mapping 
```
   docker run -e <env var>=<env data> -ti crosscloudci/k8s-infra:latest -p 4001:4001 
```
### Get name of the container 
```
   docker ps 
```
### Optional: Bash prompt 
```
  docker exec -ti <name of container> /bin/bash 
```
### Get docker ip address 
```
  docker exec -ti <name of container> ifconfig
```

### Test manually adding ip addresses
```
 docker run -ti crosscloudci/k8s-infra:latest k8s-infra/bin/k8sinfra generate_config --master-hosts "1.1.1.1,2.2.2.2,3.3.3.3" --worker-hosts "3.3.3.3,4.4.4.4,5.5.5.5" 
```

### Test manually adding ip addresses with generated cluster yml and provision generation with head release type
```
 docker run -ti crosscloudci/k8s-infra:latest /bin/bash -c "k8s-infra/bin/k8sinfra generate_config --release-type=head --master-hosts "1.1.1.1,2.2.2.2,3.3.3.3" --worker-hosts "3.3.3.3,4.4.4.4,5.5.5.5" -o /tmp/test.yml; \
 k8s-infra/bin/k8sinfra provision --config-file '/tmp/test.yml' --dry-run"  
```
### Test manually adding ip addresses with generated cluster yml and provision generation with stable release type
```
 docker run -ti crosscloudci/k8s-infra:latest /bin/bash -c "k8s-infra/bin/k8sinfra generate_config --release-type=stable --master-hosts "1.1.1.1,2.2.2.2,3.3.3.3" --worker-hosts "3.3.3.3,4.4.4.4,5.5.5.5" -o /tmp/test.yml; \
 k8s-infra/bin/k8sinfra provision --config-file '/tmp/test.yml' --dry-run"  
```

### Testing with the gitlab integration

To test with the gitlab integration (to get the source IPs from gitlab instead of manually providing them), 
you can use one of the following two options:

Pre-req: Successful provision Packet machines using infra-provisioning
Option 1: use existing pipeline

Go to https://gitlab.cncf.ci/cncf/infra-provisioning/pipelines
Find a successful pipeline and open the release job.
Under the artifacts section select browse, then download the nodes.env file under the top-level Terraform directory.
example url path: https://gitlab.cncf.ci/cncf/infra-provisioning/-/jobs/168517/artifacts/browse/terraform/nodes.env
Option 2: run new pipeline

Go to https://gitlab.cncf.ci/cncf/infra-provisioning/pipelines
Select run pipeline, then create a pipeline against the production branch.
Once the job has finished open the release job.
Under the artifacts section select browse, then download the nodes.env file under the top-level Terraform directory.
example url path: https://gitlab.cncf.ci/cncf/infra-provisioning/-/jobs/168517/artifacts/browse/terraform/nodes.env

### Test gitlab integration 

stable
```
 docker run -ti crosscloudci/k8s-infra:latest k8s-infra/bin/k8sinfra generate_config --release-type=stable --infra-job=168517 
```
head
```
 docker run -ti crosscloudci/k8s-infra:latest k8s-infra/bin/k8sinfra generate_config --release-type=head --infra-job=168517 
```
Saving to a file
```
 docker run -ti crosscloudci/k8s-infra:latest k8s-infra/bin/k8sinfra generate_config --infra-job=168517  -o /tmp/cluster.yml
```
Error message if cluster.yml structure is not valid
```
 docker run -ti crosscloudci/k8s-infra:latest k8s-infra/bin/k8sinfra provision --config-file=k8s-infra/example_hosts-invalid_syntax.yml 
```
Error message if cluster.yml structure is not valid
```
 docker run -ti crosscloudci/k8s-infra:latest k8s-infra/bin/k8sinfra provision --config-file=k8s-infra/example_hosts-invalid_structure.yml 
```
## TESTING
Develop with rspec with the installed kubespray dependencies by mapping the k8s-infra directory into the container
and running rspec spec
```
docker run -v $(pwd):/k8s-infra -v /home/pair/.ssh/id_rsa:/root/.ssh/id_rsa  -ti kubespray /bin/bash 
```
