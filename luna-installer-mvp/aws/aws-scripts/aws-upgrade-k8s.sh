#!/bin/bash
pwd
#Add variables to be called in the script 
cloud="aws"
updated_k8s_version=${1?Error: No kubernetes version given.}
luna_inputs_file="../${cloud}-k8s-cluster/inputs/dev/luna-inputs.json"
current_k8s_version=$(python3 parse-creds.py $luna_inputs_file "k8s-version")
./${cloud}-init-backends.sh k8s-cluster

#Change coredns manifest to remove upstream line if exists - this applies to kubernetes version 1.17 and below
upstream_check=$(kubectl get configmap coredns -n kube-system -o yaml | grep upstream)
if [[ $upstream_check != 0 ]]
then
    #delete deprecated upstream line from manifest
    #copy coredns to new file
    kubectl get configmap coredns -n kube-system -o yaml > updatecoredns.yaml
    #edit file to delete upstream
    sed -i '/^          upstream*/d' updatecoredns.yaml
    #apply file changes to coredns
    kubectl apply -n kube-system -f updatecoredns.yaml
    #remove updatecoredns.yaml after used
    rm updatecoredns.yaml
fi

if [[ "$current_k8s_version" ==  "$updated_k8s_version" ]]
then
    echo "Already up to date!"
    exit
else
    #Check if there are Windows nodes    
    check_node_image=$(kubectl get nodes -o wide | grep -c Windows)
    if [[ "$check_node_image" == 0 ]]
    then
        #If there are no Windows nodes run this section
        pwd
        python3 update_json.py $luna_inputs_file "k8s-version" $updated_k8s_version
        cd ../${cloud}-k8s-cluster

        #Run apply to update control plane
        terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure
        terraform plan -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/${cloud}-infra.json" -var-file="inputs/dev/luna-inputs.json" -refresh=true -parallelism=50
        terraform apply -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/${cloud}-infra.json" -var-file="inputs/dev/luna-inputs.json" -refresh=true -parallelism=50 -auto-approve
        #Grab output of terraform and make it usable for autoscaling
        autoscale_arn=$(terraform output workers_asg_arns)
        autoscale_group_linux=$(echo $autoscale_arn | cut -d'/' -f2 | grep -Eo "^luna\S*" | tr -d '",')
        #Check number of nodes currently running
        nodes_num=$(kubectl get nodes -o wide | grep -c ip-)
        nodes_doubled=$(expr ${nodes_num} \* 2)
        
        #Start to Linux upgrade for the nodes
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${autoscale_group_linux} --min-size 1 --max-size 10 --desired-capacity ${nodes_doubled}
        
        #check to see if it upgrades and scales
        autoscale_up=$(kubectl get nodes | grep -c $updated_k8s_version)
        count=0 
        while [[ $autoscale_up -ne $nodes_num && $count -le 30 ]]; do
            echo "Waiting for Nodes to Scale Up"
            sleep 5
            autoscale_up=$(kubectl get nodes | grep -c $updated_k8s_version)
            count=$((count + 1))
        done
        
        #Cordon old nodes
        OLD_VERSION="v${current_k8s_version}"
        NODES=`kubectl get nodes -o wide | grep ${OLD_VERSION} | awk '{ print $1 }'`
        for NODE in $NODES; do
        echo "Cordoning... ${NODE}"
        kubectl cordon ${NODE}
        done

        #Drain old nodes to new version
        for NODE in $NODES; do
        echo "Draining... ${NODE}"
        kubectl drain ${NODE} --delete-local-data --ignore-daemonsets
        done
        
        #Autoscale back to original node size
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${autoscale_group_linux} --min-size 1 --max-size 10 --desired-capacity ${nodes_num}
        #Check to see if it scales down the right nodes
        autoscale_down=$(kubectl get nodes | grep -c $current_k8s_version)
        
        count=0 
        while [[ $autoscale_down -ne 0 && $count -le 30 ]]; do
            echo "Waiting for Nodes to Scale Down"
            sleep 5
            autoscale_down=$(kubectl get nodes | grep -c $current_k8s_version)
            count=$((count + 1))
        done
        
        #Check the version of the nodes and plane
        server_version=$(kubectl version --short | grep Server | grep -c $updated_k8s_version)
        nodes_version=$(kubectl get nodes | grep -c $updated_k8s_version)
        if [[ $server_version == 0 && $nodes_version == 0 ]]
        then
            ./${cloud}-clean-up.sh
            echo "Error: upgrading kubernetes version. Contact Thermo Fisher to attempt manual upgrade."
            exit 1
        fi
        
    else
        #There are Windows and Linux nodes so run this else 
        pwd
        python3 update_json.py $luna_inputs_file "k8s-version" $updated_k8s_version
        cd ../${cloud}-k8s-cluster

        #cp the windows configuration file into the eks-cluster.tf
        cp ../${cloud}-additional-configs/eks-cluster-windows.tf ./eks-cluster.tf
        
        #Run apply to update control plane
        terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure
        terraform plan -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/${cloud}-infra.json" -var-file="inputs/dev/luna-inputs.json" -refresh=true -parallelism=50
        terraform apply -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/${cloud}-infra.json" -var-file="inputs/dev/luna-inputs.json" -refresh=true -parallelism=50 -auto-approve
        #Grab output of terraform and make it usable for autoscaling
        autoscale_arn=$(terraform output workers_asg_arns)
        autoscale_group_linux=$(echo $autoscale_arn | cut -d'/' -f2 | grep -Eo "^luna\S*" | tr -d '",')
        autoscale_group_windows=$(echo $autoscale_arn | cut -d'/' -f3 | grep -Eo "^luna\S*" | tr -d '",')
        #Check number of nodes currently running
        nodes_num=$(kubectl get nodes -o wide | grep -c ip-) 
        nodes_half=$(expr ${nodes_num} / 2) 

        #Start the Linux and Windows upgrade for the nodes
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${autoscale_group_linux} --min-size 1 --max-size 10 --desired-capacity ${nodes_num} 
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${autoscale_group_windows} --min-size 1 --max-size 10 --desired-capacity ${nodes_num}  
        
        
        #Check to see if it scaled up
        autoscale_up=$(kubectl get nodes | grep -c $updated_k8s_version)
        count=0 
        while [[ $autoscale_up -ne $nodes_num && $count -le 100 ]]; do
            echo "Waiting for Nodes to Scale Up"
            sleep 5
            autoscale_up=$(kubectl get nodes | grep -c $updated_k8s_version)
            count=$((count + 1))
        done

        if [ $count -eq 100 ]; then 
            echo "Exited Wait Loop because Windows Nodes took too long to join the cluster."
        fi 

        kubectl get nodes -o wide

        #Temp cordon windows nodes for testing
        echo "Adding Windows Node Taint to new Windows Nodes."
        NODES=`kubectl get nodes -o wide | grep Windows | awk '{ print $1 }'`
        for NODE in $NODES; do
        echo "Tainting Windows Nodes... ${NODE}"
        kubectl taint nodes ${NODE} key=value:NoSchedule
        echo "Cordoning... ${NODE}"
        kubectl cordon ${NODE}
        done

        #Sleep for Windows Nodes to be Cordoned
        echo "Confirming that Nodes are Cordoned"
        nodes_num=$(kubectl get nodes -o wide | grep -c Windows) 
        cordon_status=$(kubectl get node | grep -c SchedulingDisabled) 
        count=0
        while [[ $nodes_num -ne $cordon_status && $count -le 50 ]]; do
            echo "Waiting for Nodes to be Cordoned"
            sleep 5
            kubectl get nodes -o wide
            cordon_status=$(kubectl get node | grep -c SchedulingDisabled)
            count=$((count + 1))
        done
        
        kubectl get nodes -o wide
            
        
        #Cordon old nodes
        OLD_VERSION="v${current_k8s_version}"
        NODES=`kubectl get nodes -o wide | grep ${OLD_VERSION} | awk '{ print $1 }'`
        for NODE in $NODES; do
        echo "Cordoning... ${NODE}"
        kubectl cordon ${NODE}
        done

        #Drain old nodes to new version
        for NODE in $NODES; do
        echo "Draining... ${NODE}"
        kubectl drain ${NODE} --delete-local-data --ignore-daemonsets
        done

        #Autoscale back down 
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${autoscale_group_linux} --min-size 1 --max-size 10 --desired-capacity ${nodes_half}
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${autoscale_group_windows} --min-size 1 --max-size 10 --desired-capacity ${nodes_half}
        
        #Check to see if it scaled back down
        autoscale_down=$(kubectl get nodes | grep -c $current_k8s_version)
        count=0 
        while [[ $autoscale_down -ne 0 && $count -le 30 ]]; do
            echo "Waiting for Nodes to Scale Down"
            sleep 5
            autoscale_down=$(kubectl get nodes | grep -c $current_k8s_version)
            count=$((count + 1))
        done

        kubectl get nodes -o wide
        
        #Check node version and plane version to see if updated
        server_version=$(kubectl version --short | grep Server | grep -c $updated_k8s_version)
        nodes_version=$(kubectl get nodes | grep -c $updated_k8s_version)
        if [[ $server_version == 0 && $nodes_version == 0 ]]
        then
            ./${cloud}-clean-up.sh
            echo "Error: upgrading kubernetes version. Contact Thermo Fisher to attempt manual upgrade."
            exit 1
        fi
    fi

    #https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html - this update applies to version 1.17 and 1.18 of kubernetes
    #Changing the kube-proxy

    #get account id, node version, and region for kube proxy
    account_id=$(kubectl get daemonset kube-proxy --namespace kube-system -o=jsonpath='{$.spec.template.spec.containers[:1].image}' | grep -Eo '^[[:digit:]]*')
    kubeproxy_region=$(kubectl get daemonset kube-proxy --namespace kube-system -o=jsonpath='{$.spec.template.spec.containers[:1].image}' | cut -d'.' -f4)
    updatedNode_version=$(kubectl get nodes | awk '{print$5}' | cut -d'-' -f1 | grep -Eo '^v1.*' | sort -u)

    #check what version we upgraded too
    if [[ $updated_k8s_version == "1.17" ]]
    then
        #set kube-proxy to version 1.17
        kubectl set image daemonset kube-proxy -n kube-system kube-proxy=${account_id}.dkr.ecr.${kubeproxy_region}.amazonaws.com/eks/kube-proxy:${updatedNode_version}-eksbuild.1
    fi

    if [[ $updated_k8s_version == "1.18" ]]
    then
        #set kube-proxy to version 1.18
        kubectl set image daemonset kube-proxy -n kube-system kube-proxy=${account_id}.dkr.ecr.${kubeproxy_region}.amazonaws.com/eks/kube-proxy:${updatedNode_version}-eksbuild.1
    fi

    echo "Successfully upgraded kubernetes version ${updated_k8s_version}"
fi