#!/usr/bin/env bash

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

set -e

project_base=$(
  cd $(dirname $(dirname $0))
  pwd
)
version=
env_dir=${project_base}/env

python_resouce=${project_base}/env/python
pypi_resource=${project_base}/env/pypi
jdk_resource=${project_base}/env/jdk

jdk_dir=${jdk_resource}/jdk-8u345
miniconda_dir=${python_resouce}/miniconda
venv_dir=${python_resouce}/venv

echo "[INFO] env dir: ${env_dir}"
echo "[INFO] jdk dir: ${jdk_dir}"
echo "[INFO] venv dir: ${venv_dir}"

cd ${project_base}
source ./bin/common.sh

init() {

  cd ${project_base}

  echo "[INFO] install os dependency"
  bash bin/install_os_dependencies.sh
  echo "[INFO] install os dependency done"

  echo "[INFO] install python"
  if [ -d ${miniconda_dir} ] || [ -f ${miniconda_dir} ]; then
    rm -rf ${miniconda_dir}
    echo "[INFO] delete python: ${miniconda_dir}"
  fi
  bash ${python_resouce}/Miniconda3-*-Linux-x86_64.sh -b -f -p ${miniconda_dir}
  echo "[INFO] install python done"

  echo "[INFO] install jdk"
  if [ -d ${jdk_dir} ] || [ -f ${jdk_dir} ]; then
    rm -rf ${jdk_dir}
    echo "[INFO] delete jdk: ${jdk_dir}"
  fi
  cd ${jdk_resource}
  tar xJf jdk-*.tar.xz
  echo "[INFO] install jdk done"

  cd ${project_base}

  echo "[INFO] install virtualenv"
  if [ -d ${venv_dir} ] || [ -f ${venv_dir} ]; then
    rm -rf ${venv_dir}
    echo "[INFO] delete venv: ${venv_dir}"
  fi

  ${miniconda_dir}/bin/python -m pip install --upgrade pip -f ${pypi_resource} --no-index
  ${miniconda_dir}/bin/python -m venv ${venv_dir}
  source ${venv_dir}/bin/activate
  pip install setuptools --no-index -f ${pypi_resource}
  echo "[INFO] install virtualenv done"

  #mv "${project_base}/fate/fate_test" "${project_base}"
  echo "[INFO] install python dependency packages by ${project_base}/requirements.txt using ${pypi_resource}"
  pip install -r ${project_base}/fate_test/python/requirements.txt -f ${pypi_resource} --no-index
  pip install -r ${project_base}/fate_client/python/requirements.txt -f ${pypi_resource} --no-index
  pip install -r ${project_base}/requirements.txt -f ${pypi_resource} --no-index
  pip install -r ${project_base}/requirements-fate.txt -f ${pypi_resource} --no-index
  pip install -r ${project_base}/requirements-flow.txt -f ${pypi_resource} --no-index
  pip install -r ${project_base}/requirements-rabbitmq.txt -f ${pypi_resource} --no-index
  pip install -r ${project_base}/requirements-pulsar.txt -f ${pypi_resource} --no-index
  pip install -r ${project_base}/requirements-spark.txt -f ${pypi_resource} --no-index
  pip install -r ${project_base}/requirements-container.txt -f ${pypi_resource} --no-index
  echo "[INFO] install python dependency packages done"

  echo "[INFO] install fate client"
  cd ${project_base}/fate_client/python/
  python setup.py install
  flow init --ip 127.0.0.1 --port 9380
  echo "[INFO] install fate client done"

  echo "[INFO] install fate test"
  cd ${project_base}/fate_test/python
  python setup.py install
  fate_test config new
  sed -i "s#data_base_dir:.*#data_base_dir: ${project_base}#g" ./fate_test_config.yaml
  sed -i "s#fate_base:.*#fate_base: ${project_base}/fate#g" ./fate_test_config.yaml
  echo "[INFO] install fate test done"

  echo "[INFO] setup fateflow"
  sed -i "s#PYTHONPATH=.*#PYTHONPATH=${project_base}/fate/python:${project_base}/fate_flow/python#g" ${project_base}/fate_flow/bin/init_env.sh
  sed -i "s#venv=.*#venv=${venv_dir}#g" ${project_base}/fate_flow/bin/init_env.sh
  sed -i "s#JAVA_HOME=.*#JAVA_HOME=${jdk_dir}#g" ${project_base}/fate_flow/bin/init_env.sh
  ln -frs "${project_base}/fate/python" "${project_base}/python"
  echo "[INFO] setup fateflow done"

  echo "[INFO] setup fateboard"
  sed -i "s#fateflow.url=.*#fateflow.url=http://localhost:9380#g" ${project_base}/fateboard/conf/application.properties
  echo "[INFO] setup fateboard done"
}

action() {
  cd $project_base

  source $project_base/fate_flow/bin/init_env.sh

  cd $project_base/fate_flow
  bash bin/service.sh $1

  #cd $project_base/fateboard
  #bash service.sh $1

  cd $project_base
}

case "$1" in
start)
  action $@
  ;;

stop)
  action $@
  ;;

status)
  action $@
  ;;

init)
  init
  ;;
*)
  echo "usage: $0 {start|stop|status|init}"
  exit -1
  ;;
esac
