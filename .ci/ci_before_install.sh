#!/bin/bash
# author: Robert Penicka
set -e

distro=`lsb_release -r | awk '{ print $2 }'`
[ "$distro" = "18.04" ] && ROS_DISTRO="melodic"
[ "$distro" = "20.04" ] && ROS_DISTRO="noetic"

echo "Starting install preparation"

openssl aes-256-cbc -K $encrypted_f2b1af48ae35_key -iv $encrypted_f2b1af48ae35_iv -in ./.ci/deploy_key_github.enc -out ./.ci/deploy_key_github -d
eval "$(ssh-agent -s)"
chmod 600 ./.ci/deploy_key_github
ssh-add ./.ci/deploy_key_github

sudo apt-get -y update -qq
sudo apt-mark hold openssh-server

sudo apt-get -y upgrade --fix-missing

sudo apt-get -y install git

echo "installing uav_core pre-requisities"
git clone https://github.com/ctu-mrs/uav_core
cd uav_core
./installation/install.sh

echo "clone simulation"
cd
git clone https://github.com/ctu-mrs/simulation.git
cd simulation

echo "running the main install.sh"
./installation/install.sh

gitman update

# get the current commit SHA
cd "$TRAVIS_BUILD_DIR"
SHA=`git rev-parse HEAD`

# get the current package name
PACKAGE_NAME=${PWD##*/}

# checkout the SHA
cd ~/simulation/.gitman/$PACKAGE_NAME
git checkout "$SHA"

# will need this to test the compilation
sudo apt-get -y install python-catkin-tools

mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/src
ln -s ~/simulation
source /opt/ros/$ROS_DISTRO/setup.bash
cd ~/catkin_ws
catkin init

echo "install part ended"
