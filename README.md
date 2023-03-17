## Set AWS DEFAULT REGION

```bash
export AWS_DEFAULT_REGION=$(curl --silent http://169.254.169.254/latest/meta-data/placement/region) && echo $AWS_DEFAULT_REGION
```

## Create eks cluster

```bash
eksctl create cluster --name eks-lab-cluster --nodegroup-name worknodes-1 --node-type t3.medium --nodes 2 --nodes-min 1 --nodes-max 4 --managed --region ${AWS_DEFAULT_REGION}
```

## Test the website container and stop it after testing

```bash
docker run -P -d -p 8080:80 website

docker stop 572180f49857
```

## Create ecr repository for website and sidecar

```bash
aws ecr create-repository --repository-name website --region ${AWS_DEFAULT_REGION}

aws ecr create-repository --repository-name sidecar --region ${AWS_DEFAULT_REGION}
```

## Save lab info to environment

```bash
export ACCOUNT_NUMBER=$(aws sts get-caller-identity \
 --query 'Account' \
 --output text)
 
 export ECR_REPO_URI_WEBSITE=$(aws ecr describe-repositories \
 --repository-names website \
 --region ${AWS_DEFAULT_REGION} \
 --query 'repositories[*].repositoryUri' \
 --output text)
 
 export ECR_REPO_URI_SIDECAR=$(aws ecr describe-repositories \
 --repository-names sidecar \
 --region ${AWS_DEFAULT_REGION} \
 --query 'repositories[*].repositoryUri' \
 --output text)
 ```
 
 ## Login to AWS ECR repository
 
 ```bash
 aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ACCOUNT_NUMBER.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
 ```
 
 ## Tag and push website and sidecar container to ECR
 
 ```bash
 docker tag website:latest $ECR_REPO_URI_WEBSITE:latest
 
 docker tag sidecar:latest $ECR_REPO_URI_SIDECAR:latest
 
 docker push $ECR_REPO_URI_WEBSITE:latest
 
 docker push $ECR_REPO_URI_WEBSITE:latest
 ```
 
 ```bash
 echo "export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" >> ~/.bash_profile
 
 aws configure set default.region $AWS_DEFAULT_REGION
 ```
 
 ## Check the status of the cluster
 
 ```bash
 aws eks describe-cluster --name eks-lab-cluster --query 'cluster.status' --output text
 ```
 
 ## Update kubeconfig if not already done
 
 ```bash
 aws eks update-kubeconfig \
 --region $AWS_DEFAULT_REGION \
 --name eks-lab-cluster
 ```
 
 ## Install the AWS LoadBalancer controller (Old name - ALB Ingress Controller)
 
 ```bash
 sh ./albController.sh
 ```
 
 if getting error similar to `error: exec plugin: invalid apiVersion "client.authentication.k8s.io/v1alpha1"` try updating the aws-cli version and or the kubectl version to match the control plane version
 
 ```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
```

## Deploying the applications

## Create a namespace and deploy the application

```bash
kubectl create namespace containers-lab

envsubst < eks-lab-app/k8s-all.yaml | kubectl apply -f -
```

## Check what is deployed

```bash
kubectl get pod -n containers-lab

kubectl get pod,svc -n containers-lab

kubectl get ingress -n containers-lab
```

Ingress Output

```bash
NAME          CLASS    HOSTS   ADDRESS                                                                  PORTS   AGE
lab-ingress   <none>   *       k8s-containe-labingre-3207ffb4ea-266476303.us-west-2.elb.amazonaws.com   80      114s
```

## Create iam role for service account to allow pods call aws api with service account

```bash
eksctl create iamserviceaccount --name iampolicy-sa --namespace containers-lab \
  --cluster eks-lab-cluster --role-name "eksRole4serviceaccount" \
  --attach-policy-arn arn:aws:iam:$ACCOUNT_NUMBER:policy/eks-lab-read-policy \
  --approve --override-existing-serviceaccounts
  
eksctl create iamserviceaccount --name iampolicy-sa --namespace containers-lab \
    --cluster eks-lab-cluster --role-name "eksRole4serviceaccount" \
    --attach-policy-arn arn:aws:iam::$ACCOUNT_NUMBER:policy/eks-lab-read-policy \
    --approve --override-existing-serviceaccounts
```


## Check the service account created

```bash
kubectl get sa iampolicy-sa -n containers-lab -o yaml
```

## Update the deployment to use the service account 

```bash
kubectl set serviceaccount deployment eks-lab-deploy iampolicy-sa -n containers-lab

kubectl describe deployment eks-lab-deploy -n containers-lab | grep 'Service Account'
```

## Deploy CloudWatch Container Insight

```bash
export instanceId=$(aws ec2 describe-instances --filters Name=instance-type,Values=t3.medium --query "Reservations[0].Instances[*].InstanceId" --output text)

export instanceProfileArn=$(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[*].Instances[*].IamInstanceProfile.Arn' --output text)

export instanceProfileName=$(echo $instanceProfileArn | awk -F/ '{print $NF}')

export roleName=$(aws iam get-instance-profile --instance-profile-name $instanceProfileName --query "InstanceProfile.Roles[*].RoleName" --output text)

aws iam attach-role-policy --role-name $roleName --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

```
 
 ## Deploy CloudWatch container insight
 
 ```bash
 export CLUSTER_NAME=$(aws eks describe-cluster --name eks-lab-cluster --query 'cluster.name' --output text)
 
 curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | \
 sed "s/{{cluster_name}}/$CLUSTER_NAME/;s/{{region_name}}/$AWS_DEFAULT_REGION/" | \
 kubectl apply -f -
 ```

## Check the pods

```bash
kubectl get pod -w -n amazon-cloudwatch
```

Go to CloudWatch > Insights > Container Insight. Select a cluster to view performance of the resources.