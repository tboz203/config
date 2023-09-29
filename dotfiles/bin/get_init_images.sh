#!/bin/bash
kubectl get pod -o custom-columns=name:.metadata.name,images:.spec.containers[*].image,init-image:.spec.initContainers[*].image
