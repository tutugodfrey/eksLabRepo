#!/bin/sh

cp /metadata2.json /var/metadata/metadata2.json

export cond1="aws sts get-caller-identity"
export cond2="aws eks list-clusters --region us-west-2"

while (! aws sts get-caller-identity) || (! aws eks list-clusters --region us-west-2)
do
    sleep 2
done

export awsAccount=`aws sts get-caller-identity --query "Account" --output text`
export clusterName=`aws eks describe-nodegroup --cluster-name eks-lab-cluster --nodegroup-name worknodes-1 --region us-west-2 --query "nodegroup.clusterName" --output text`
export clusterVersion=`aws eks describe-nodegroup --cluster-name eks-lab-cluster --nodegroup-name worknodes-1 --region us-west-2 --query "nodegroup.version" --output text`
export creationTime=`aws eks describe-nodegroup --cluster-name eks-lab-cluster --nodegroup-name worknodes-1 --region us-west-2 --query "nodegroup.createdAt" --output text`
export instanceType=`aws eks describe-nodegroup --cluster-name eks-lab-cluster --nodegroup-name worknodes-1 --region us-west-2 --query "nodegroup.instanceTypes" --output text`
export time=$(date +%s) 
sleep 5
cat << EOF > /var/metadata/metadata2.json
{"awsAccId": "$awsAccount", "name": "$clusterName", "version": "$clusterVersion", "time": "$creationTime", "type": "$instanceType", "deployTime": "$time"}
EOF


while :
do
    sleep 10
done
