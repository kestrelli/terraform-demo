#!/bin/bash
kubectl delete svc clb-direct-pod
kubectl delete deploy real-ip-demo
kubectl patch cm tke-service-controller-config -n kube-system --patch '{"data":{"GlobalRouteDirectAccess":"false"}}'