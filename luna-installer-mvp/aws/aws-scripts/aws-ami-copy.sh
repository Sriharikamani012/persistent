#!/bin/bash
#This script is not run as part of the installer. Instead it is a helpful script to help the installer support more regions.


# List of Available regions
# us-east-2
# us-east-1
# us-west-1
# us-west-2
# af-south-1
# ap-east-1
# ap-south-1
# ap-northeast-3
# ap-northeast-2
# ap-southeast-1
# ap-southeast-2
# ap-northeast-1
# ca-central-1
# cn-north-1
# cn-northwest-1
# eu-central-1
# eu-west-1
# eu-south-1
# eu-north-1
# eu-west-2
# eu-west-3
# me-south-1
# sa-east-1
# us-gov-east-1
# us-gov-west-1

#Write the desired regions
regions=( us-east-2 us-east-1 us-west-1 us-west-2 ) 

#Create Public AMI for all of the regions from the origional AMI
for u in "${regions[@]}"
do
    echo "$u "
    ami=$(aws ec2 copy-image --source-image-id ami-0b9679f9509e275c3 --no-encrypted --source-region us-east-2 --region $u --name "Ubuntu-18.04-K8s-Infra-Prereqs" --query "ImageId")

    ami=$(echo "$ami" | sed -e 's/^"//' -e 's/"$//')

    #update python with the ami id 
    python3 update_json.py ../aws-additional-configs/aws-ami.json $u $ami
done

#Wait for the AMI's to be created ~10 minutes
echo "Go get a cup of coffee this will take ~ 10 minutes to provision."
sleep 1000

#Make AMI Public
for u in "${regions[@]}"
do
    echo "$u"
    ami=$(python3 parse-creds.py ../aws-additional-configs/aws-ami.json $u)
    echo $ami
    aws configure set region $u

    #Update python with the ami id 
    aws ec2 modify-image-attribute --image-id $ami --launch-permission "Add=[{Group=all}]" 
done
