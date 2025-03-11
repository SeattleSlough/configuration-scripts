#!/bin/bash

# ---------update && upgrade--------
echo "Updating Ubuntu"

sudo apt update
sudo apt upgrade -y




# --------install basic packages----------
echo "Installing required packages"

sudo apt install -y gnupg software-properties-common curl wget  tree xclip gettext ca-certificates lsb-release
sudo apt-get update
sudo apt-get install -y apt-transport-https gpg




# --------install and configure git---------
echo "Installing and configuring git"

sudp apt install -y git
git config --global user.name "Michael Maggs"
git config --gloab user.email "seattleslew@runawayserver.com"




# ---------install Python, Pip & Go----------
echo "Installing Python, Pip, and Golang"

sudo apt install -y python python3-pip golang




# ------install terraform---------
echo "installing Terraform"

# download keyring
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# validate package
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt-get install -y terraform





# -------Install containerd-------
echo "Installing containerd"

# install runc
# wget https://github.com/opencontainers/runc/releases/download/v1.2.5/runc.amd64
# sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# #install cni
# wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz
# mkdir -p /opt/cni/bin
# tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.2.tgz

# install dependencies
# sudo apt install -y ca-certificates lsb-release

# download GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# add Docker repository & install
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install containerd.io

# start & enable
sudo systemctl start containerd
sudo systemctl enable containerd



# ------------install nerdctl-------------
echo "Installing nerdctl"

wget https://github.com/containerd/nerdctl/releases/download/v2.0.3/nerdctl-full-2.0.3-linux-amd64.tar.gz
tar -zxf nerdctl-full-2.0.3-linux-amd64.tar.gz nerdctl
sudo mv nerdctl /usr/bin/nerdctl
rm nerdctl-full-2.0.3-linux-amd64.tar.gz




# ----------Kubernetes------------
echo "Installing Kubernetes tool & kind"

sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
# sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# install
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# install kind
go install sigs.k8s.io/kind@v0.27.0




# ----------install Helm, AWS & GCP CLI-----------
echo "Installing AWS & GCP CLIs"

sudo snap install helm --classic
sudo snap install aws-cli --classic
sudo snap install google-cloud-cli --classic




# -----------install eksctl----------
echo "Installing eksctl"

# for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# (Optional) Verify checksum
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check

tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz

sudo mv /tmp/eksctl /usr/local/bin




# -------------.basrc additions-------------
echo "Updating .bashrc"

cat <<EOF >> .bashrc


cd ~

PROMPT_DIRTRIM=1

parse_git_branch() {
      git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
    }

PS1="\[\e[32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\e[36m\]\$(parse_git_branch)\[\e[0m\]$ "

alias k='kubectl'
alias ..='cd ..'
alias ...='cd ../..'
alias ci='code-insiders'

EOF




# -------install Docker---------
echo "Installing Docker"

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# add non-root privileges
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker