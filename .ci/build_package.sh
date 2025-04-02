#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

ARTIFACTS_FOLDER=$1
BASE_IMAGE=$2

PACKAGE_PATH=/tmp/package_copy
mkdir -p $PACKAGE_PATH

cp -r $MY_PATH/.. $PACKAGE_PATH/

## | ------------ detect current CPU architecture ------------- |

CPU_ARCH=$(uname -m)
if [[ "$CPU_ARCH" == "x86_64" ]]; then
  echo "$0: detected amd64 architecture"
  ARCH="amd64"
else
  echo "$0: amd64 architecture not detected, assuming arm64"
  ARCH="arm64"
fi

## | ---------------- check if we are on a tag ---------------- |

cd $PACKAGE_PATH
# GIT_TAG=$(git describe --exact-match --tags HEAD || echo "")

# if [[ "$GIT_TAG" == "" ]]; then
#   echo "$0: git tag not recognized! PX4 requires the current commit to be tagged with, e.g., v1.12.1-dev tag."
#   exit 1
# fi

## | ------------------ install dependencies ------------------ |

sudo apt-get -y update

rosdep update

# without this, the lxml package won't be installed from the internal python dependencies
sudo apt-get -y install libxslt1-dev

rosdep install -y -v --rosdistro=jazzy --from-paths ./

sudo apt-get -y install python3-pip python3-colcon-common-extensions

# PX4-specific dependency
python3 -m pip install --user -r $PACKAGE_PATH/Tools/setup/requirements.txt
$PACKAGE_PATH/Tools/setup/ubuntu.sh --no-nuttx --no-sim-tool

## | ---------------- prepare colcon workspace ---------------- |

WORKSPACE_PATH=/tmp/workspace

mkdir -p $WORKSPACE_PATH/src
cd $WORKSPACE_PATH/

source /opt/ros/jazzy/setup.bash

colcon init
# colcon config --profile release --cmake-args -DCMAKE_BUILD_TYPE=Release
# colcon profile set release
# colcon config --install

ln -sf $PACKAGE_PATH $WORKSPACE_PATH/src/px4

## | ------------------------ build px4 ----------------------- |

cd $WORKSPACE_PATH
colcon build --limit-status-rate 0.2 --summarize --verbose

## | -------- extract build artefacts into deb package -------- |

TMP_PATH=/tmp/px4

mkdir -p $TMP_PATH/package/DEBIAN
mkdir -p $TMP_PATH/package/opt/ros/jazzy/share

cp -r $WORKSPACE_PATH/install/share/px4 $TMP_PATH/package/opt/ros/jazzy/share

# extract package version
VERSION=$(cat $PACKAGE_PATH/package.xml | grep '<version>' | sed -e 's/\s*<\/*version>//g')
echo "$0: Detected version $VERSION"

echo "Package: ros-jazzy-px4
Version: $VERSION
Architecture: $ARCH
Maintainer: Tomas Baca <tomas.baca@fel.cvut.cz>
Description: PX4" > $TMP_PATH/package/DEBIAN/control

cd $TMP_PATH

sudo apt-get -y install dpkg-dev

dpkg-deb --build --root-owner-group package
dpkg-name package.deb

mv *.deb $ARTIFACTS_FOLDER/