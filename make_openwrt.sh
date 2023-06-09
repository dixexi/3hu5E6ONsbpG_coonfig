#!/bin/bash

# debian

usage() {
  echo "usage: $0 [-j NUM_JOBS] [-d] [-h]"
  echo ""
  echo "Build script for my project."
  echo ""
  echo "optional arguments:"
  echo "  -j NUM_JOBS   number of concurrent jobs for make"
  echo "  -d            build inside a Docker container"
  echo "  -h            show this help message and exit"
}

while getopts ":j:cdh" opt; do
  case ${opt} in
    j )
      num_jobs=$OPTARG
      ;;
    d )
      docker_build=true
      ;;
    c )
      clean_build=true
      ;;
    h )
      usage
      exit 0
      ;;
    \? )
     echo "Invalid option: -$OPTARG" 1>&2
     usage
     exit 1
     ;;
    : )
     echo "Option -$OPTARG requires an argument." 1>&2
     usage
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))

num_jobs=${num_jobs:-$(nproc)}

# 设置代码仓库地址
repo_url="https://github.com/coolsnowwolf/lede.git"

# 判断代码仓库是否已经被clone
if [ ! -d "lede" ]; then
  # 如果没有clone，则执行clone命令
  echo "Code repository not found, cloning..."
  git clone $repo_url
else
  # 如果已经被clone，则执行pull命令进行更新
  echo "Code repository found, updating..."
  cd lede
  git pull
  cd ..
fi

cp a.config lede/.config
cd lede/

sudo sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
sudo apt-get update -y
sudo apt-get full-upgrade -y
sudo apt-get install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev \
libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz \
mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pyelftools \
libpython3-dev qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip \
vim wget xmlto xxd zlib1g-dev

if [ "$clean_build" = true ]; then
  make clean
fi

sed -i '$a src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '$a src-git small https://github.com/kenzok8/small' feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a

make download V=s -j$num_jobs
make FORCE_UNSAFE_CONFIGURE=1 V=s -j$num_jobs
if [ $? -ne 0 ]; then
  echo "ERROR: make command failed"
  exit 1
fi

if [ "$docker_build" = true ]; then
  cd ../
  rm -rf docker-openwrt/
  mkdir docker-openwrt/
  cp lede/openwrt-x86-64-generic-ext4-rootfs.img.gz docker-openwrt/
  cp zabbix_agentd.conf docker-openwrt/
  cp Dockerfile docker-openwrt/
  cd docker-openwrt/
  docker build -t vrouter:test .
fi

