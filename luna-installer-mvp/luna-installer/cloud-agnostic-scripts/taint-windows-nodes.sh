#!/bin/bash

#Confirm Windows Nodes are present
echo "Confirming Windows Nodes are present."
windows_nodes=$(kubectl get nodes -o wide | grep -c Windows)
count=0
while [[ $windows_nodes -ne 3 && $count -le 50 ]]; do
    echo "Waiting for Windows Nodes"
    sleep 5
    windows_nodes=$(kubectl get nodes -o wide | grep -c Windows)
    count=$((count + 1))
done


echo "Adding Windows Node Taint."
NODES=`kubectl get nodes -o wide | grep Windows | awk '{ print $1 }'`
for NODE in $NODES; do
    echo "Tainting Windows Nodes... ${NODE}"
    kubectl taint nodes ${NODE} key=value:NoSchedule
    echo "Cordoned... ${NODE}"
    kubectl cordon ${NODE}
    echo "Drained... ${NODE}"
    kubectl drain ${NODE} --delete-local-data --ignore-daemonsets
done
