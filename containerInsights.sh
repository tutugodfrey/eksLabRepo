#!/bin/bash
# Attach policy "CloudWatchAgentServerPolicy" to the IAM role of your worker nodes
# Ref: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-prerequisites.html
export instanceId=`aws ec2 describe-instances --filters Name=instance-type,Values=t3.medium --query "Reservations[0].Instances[*].InstanceId" --output text`
export instanceProfileArn=`aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[*].Instances[*].IamInstanceProfile.Arn' --output text`
export instanceProfileName=`echo $instanceProfileArn | awk -F/ '{print $NF}'`
export roleName=`aws iam get-instance-profile --instance-profile-name $instanceProfileName --query "InstanceProfile.Roles[*].RoleName" --output text`
aws iam attach-role-policy --role-name $roleName --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
# Container Insights setup
# Ref: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-EKS-quickstart.html
export CLUSTER_NAME=`aws eks describe-cluster --name eks-lab-cluster --query 'cluster.name' --output text`
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/$CLUSTER_NAME/;s/{{region_name}}/us-west-2/" | kubectl apply -f -