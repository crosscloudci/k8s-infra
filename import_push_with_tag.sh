#!/bin/bash
docker load -i ./kube-apiserver.tar
docker load -i ./kube-controller-manager.tar
docker load -i ./kube-proxy.tar
docker load -i ./kube-scheduler.tar
docker tag k8s.gcr.io/kube-apiserver-$2:$1 crosscloudci/kube-apiserver:$1.$2
docker tag k8s.gcr.io/kube-controller-manager-$2:$1 crosscloudci/kube-controller-manager:$1.$2
docker tag k8s.gcr.io/kube-proxy-$2:$1 crosscloudci/kube-proxy:$1.$2
docker tag k8s.gcr.io/kube-scheduler-$2:$1 crosscloudci/kube-scheduler:$1.$2
docker push crosscloudci/kube-apiserver:$1.$2
docker push crosscloudci/kube-controller-manager:$1.$2
docker push crosscloudci/kube-proxy:$1.$2
docker push crosscloudci/kube-scheduler:$1.$2
