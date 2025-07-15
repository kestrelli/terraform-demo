#!/bin/bash
CLB_IP=$(kubectl get svc clb-direct-pod -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s http://$CLB_IP | grep remote_addr