#!/bin/bash
# Move to Cloud9 bootstrap
sudo yum update -y

# Get python version; need >= 3.7
eval $(python -c "import sys;print('major={} minor={} micro={}-{}-{}'.format(*sys.version_info))")
if [ $major -ne 3 -o $minor -lt 7 ]; then
     # Update python
     sudo yum install python38 -y
     # Get python 3.8 from the linux-extras
     sudo amazon-linux-extras install python3.8 -y
fi
# Install pip
curl -O https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py --user

# Upgrade aws cli
pip3 install --upgrade --user awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install

# Create bin directory in $HOME
mkdir -p $HOME/bin && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc

## Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
cp ./kubectl $HOME/bin/kubectl
# Test version
$HOME/bin/kubectl version --client --short

# Install aws-iam-authenticator
curl -o aws-iam-authenticator https://s3.us-west-2.amazonaws.com/amazon-eks/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator
cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator
$HOME/bin/aws-iam-authenticator version

## Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

## Install helm
curl -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 755 get_helm.sh
./get_helm.sh
helm version

. ~/.bashrc
hash -r