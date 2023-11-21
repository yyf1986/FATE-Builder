#!/bin/bash

#
#  Copyright 2019 The FATE Authors. All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
if [[ $1 == "root" ]];then
  command=""
else
  command="sudo"
fi
echo $command
system=`sed -e '/"/s/"//g' /etc/os-release | awk -F= '/^NAME/{print $2}'`
echo ${system}

case "${system}" in
    "CentOS Linux")
            echo "test0"
	    echo "CentOS System"
	    $command sed -e "s!^mirrorlist=!#mirrorlist=!g" -e "s!^#baseurl=!baseurl=!g"  -e "s!http://mirror\.centos\.org!http://mirrors.tencentyun.com!g" -i /etc/yum.repos.d/CentOS-*.repo 
	    #$command cat /etc/yum.repos.d/CentOS-Base.repo

	    $command sed -e "s!^metalink=!#metalink=!g" -e "s!^#baseurl=!baseurl=!g" -e "s!http://download\.example/pub!http://mirrors.tencentyun.com!g" -i /etc/yum.repos.d/epel*.repo 
            $command yum clean all && yum makecache fast
	    echo "test1"
            $command yum -y install gcc gcc-c++ make openssl-devel supervisor gmp-devel mpfr-devel libmpc-devel libaio numactl autoconf automake libtool libffi-devel snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4-devel libasan lsof
            echo "test2"
	    ;;
    "Ubuntu")
            echo "Ubuntu System"
            $command apt-get install -y gcc g++ make  openssl supervisor libgmp-dev  libmpfr-dev libmpc-dev libaio1 libaio-dev numactl autoconf automake libtool libffi-dev libssl1.0.0 libssl-dev  liblz4-1 liblz4-dev liblz4-1-dbg liblz4-tool  zlib1g zlib1g-dbg zlib1g-dev
            cd /usr/lib/x86_64-linux-gnu
            if [ ! -f "libssl.so.10" ];then
                 $command ln -s libssl.so.1.0.0 libssl.so.10
                 $command ln -s libcrypto.so.1.0.0 libcrypto.so.10
            fi
            ;;
    *)
            echo "Not support this system."
            exit -1
esac
