# k8s-infra
K8s-Infra

## setup

## testing

# Docker

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

### Test manually adding ip addresses with generated cluster yml and provision generation
```
 docker run -ti crosscloudci/k8s-infra:latest /bin/bash -c "k8s-infra/bin/k8sinfra generate_config --master-hosts "1.1.1.1,2.2.2.2,3.3.3.3" --worker-hosts "3.3.3.3,4.4.4.4,5.5.5.5" -o /tmp/test.yml; \
 k8s-infra/bin/k8sinfra provision --config-file '/tmp/test.yml' --dry-run"  
```
