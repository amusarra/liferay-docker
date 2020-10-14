#!/bin/bash

function check_liferay_additional_files() {
  local found_additional_files=()

  local regex_osgi_dependencies='liferay-(dxp|ce)-(dependencies|osgi)-(([0-9]+\.)?([0-9]+\.)?(\*|[0-9]+)).+'
  local regex_war='liferay-(dxp|ce)-(([0-9]+\.)?([0-9]+\.)?(\*|[0-9]+)).+'

  for additional_file in "${1}"/liferay-*; do
    if [[ $additional_file =~ $regex_osgi_dependencies ]]; then

      if [[ ${BASH_REMATCH[2]} == "osgi" ]]; then
        found_additional_files+=("${additional_file}")
      fi

      if [[ ${BASH_REMATCH[2]} == "dependencies" ]]; then
        found_additional_files+=("${additional_file}")
      fi
    fi

    if [[ $additional_file =~ $regex_war ]]; then
      if [[ ${additional_file} == *.war ]]; then
        found_additional_files+=("${additional_file}")
      fi
    fi
  done

  echo "${found_additional_files[*]}"
}

function check_utils() {

  #
  # https://stackoverflow.com/a/677212
  #

  for util in "${@}"; do
    command -v ${util} >/dev/null 2>&1 || {
      echo >&2 "The utility ${util} is not installed."
      exit 1
    }
  done
}

function clean_up_temp_directory() {
  rm -fr ${TEMP_DIR}
}

function configure_tomcat() {
  printf "\nCATALINA_OPTS=\"\${CATALINA_OPTS} \${LIFERAY_JVM_OPTS}\"" >>${TEMP_DIR}/liferay/tomcat/bin/setenv.sh
}

function date() {
  export LC_ALL=en_US.UTF-8

  if [ -z ${1+x} ] || [ -z ${2+x} ]; then
    if [ "$(uname)" == "Darwin" ]; then
      echo $(/bin/date)
    elif [ -e /bin/date ]; then
      echo $(/bin/date)
    else
      echo $(/usr/bin/date)
    fi
  else
    if [ "$(uname)" == "Darwin" ]; then
      echo $(/bin/date -jf "%a %b %e %H:%M:%S %Z %Y" "${1}" "${2}")
    elif [ -e /bin/date ]; then
      echo $(/bin/date -d "${1}" "${2}")
    else
      echo $(/usr/bin/date -d "${1}" "${2}")
    fi
  fi
}

function download() {
  local file_name=${1}

  if [ -e ${file_name} ]; then
    return
  fi

  local file_url=${2}

  if [[ ${file_url} != http*://* ]]; then
    file_url=http://${file_url}
  fi

  if [[ ${file_url} != http://mirrors.*.liferay.com* ]] &&
    [[ ${file_url} != http://release-1* ]] &&
    [[ ${file_url} != https://release.liferay.com* ]]; then
    if [ ! -n "${LIFERAY_DOCKER_MIRROR}" ]; then
      LIFERAY_DOCKER_MIRROR=lax
    fi

    file_url=http://mirrors.${LIFERAY_DOCKER_MIRROR}.liferay.com/${file_url##*//}
  fi

  echo ""
  echo "Downloading ${file_url}."
  echo ""

  mkdir -p $(dirname ${file_name})

  curl ${LIFERAY_DOCKER_CURL_OPTIONS} -f -o ${file_name} ${file_url} || exit 2
}

function get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

function get_docker_image_tags_args() {
  local docker_image_tags_args=""

  for docker_image_tag in "${@}"; do
    docker_image_tags_args="${docker_image_tags_args} --tag ${docker_image_tag}"
  done

  echo ${docker_image_tags_args}
}

function get_jboss_version() {
  local regex_jboss_version='jboss-eap-(([0-9]+\.)?([0-9]+\.)?(\*|[0-9]+)).zip'

  for temp_file_name in "${1}"/jboss-eap-*; do
    if [[ $temp_file_name =~ $regex_jboss_version ]]; then
      if [[ -n ${BASH_REMATCH[1]} ]]; then
        local liferay_jboss_version=${BASH_REMATCH[1]}
      fi
    fi
  done

  if [[ -z ${liferay_jboss_version} ]]; then
    echo "Unable to determine JBoss EAP version."

    exit 1
  fi

  echo "${liferay_jboss_version}"
}

function get_jboss_archive() {
  local regex_jboss_version='jboss-eap-(([0-9]+\.)?([0-9]+\.)?(\*|[0-9]+)).zip'

  for temp_file_name in "${1}"/jboss-eap-*; do
    if [[ $temp_file_name =~ $regex_jboss_version ]]; then
      if [[ -n ${BASH_REMATCH[0]} ]]; then
        local liferay_jboss_archive=${temp_file_name}
      fi
    fi
  done

  if [[ -z ${liferay_jboss_archive} ]]; then
    echo "Unable to determine JBoss EAP Archive."

    exit 1
  fi

  echo "${liferay_jboss_archive}"
}

function get_jboss_patch_archive() {
  local regex_jboss_patch_archive='jboss-eap-(([0-9]+\.)?([0-9]+\.)?(\*|[0-9]+))-patch.zip'

  for temp_file_name in "${1}"/jboss-eap-*; do
    if [[ $temp_file_name =~ $regex_jboss_patch_archive ]]; then
      if [[ -n ${BASH_REMATCH[0]} ]]; then
        local liferay_jboss_patch_archive=${temp_file_name}
      fi
    fi
  done

  if [[ -z ${liferay_jboss_patch_archive} ]]; then
    echo "Unable to determine JBoss EAP Patch Archive."

    exit 1
  fi

  echo "${liferay_jboss_patch_archive}"
}

function get_patching_tool_archive() {
  local regex_patching_tool_version='patching-tool-(([0-9]+\.)?([0-9]+\.)?(\*|[0-9]+)).+'

  for temp_file_name in "${1}"/patching-tool-*; do
    if [[ $temp_file_name =~ $regex_patching_tool_version ]]; then
      if [[ -n ${BASH_REMATCH[0]} ]]; then
        local patching_tool_archive=${temp_file_name}
      fi
    fi
  done

  if [[ -z ${patching_tool_archive} ]]; then
    echo "Unable to determine Patching Tool Archive."

    exit 1
  fi

  echo "${patching_tool_archive}"
}

function get_tomcat_version() {
  if [ -e ${1}/tomcat-* ]; then
    for temp_file_name in $(ls ${1}); do
      if [[ ${temp_file_name} == tomcat-* ]]; then
        local liferay_tomcat_version=${temp_file_name#*-}
      fi
    done
  fi

  if [ -z ${liferay_tomcat_version+x} ]; then
    echo "Unable to determine Tomcat version."

    exit 1
  fi

  echo ${liferay_tomcat_version}
}

function install_fix_pack() {
  for temp_file_name in "${1}"/liferay-fix-pack-*; do
    if [[ -e ${temp_file_name} ]]; then
      echo "Copy the Liferay Fix Pack ${temp_file_name}" in ${TEMP_DIR}/liferay/patching-tool/patches
      cp "${temp_file_name}" ${TEMP_DIR}/liferay/patching-tool/patches
    fi
  done

  if [ "$(ls -A ${TEMP_DIR}/liferay/patching-tool/patches/)" ]; then

    if (${TEMP_DIR}/liferay/patching-tool/patching-tool.sh install); then
      rm -fr ${TEMP_DIR}/liferay/osgi/state/*
      rm -f ${TEMP_DIR}/liferay/patching-tool/patches/*

      echo ""
      echo "Fix Pack applied successfully."
    fi
  fi
}

function install_hotfix() {
  for temp_file_name in "${1}"/liferay-hotfix-*; do
    if [[ -e ${temp_file_name} ]]; then
      echo "Copy the Liferay Hotfix ${temp_file_name}" in ${TEMP_DIR}/liferay/patching-tool/patches
      cp "${temp_file_name}" ${TEMP_DIR}/liferay/patching-tool/patches
    fi
  done

  if [ "$(ls -A ${TEMP_DIR}/liferay/patching-tool/patches/)" ]; then

    if (${TEMP_DIR}/liferay/patching-tool/patching-tool.sh install); then
      rm -fr ${TEMP_DIR}/liferay/osgi/state/*
      rm -f ${TEMP_DIR}/liferay/patching-tool/patches/*

      echo ""
      echo "Hotfix applied successfully."
    fi
  fi
}

function install_jboss_patch() {
  local jboss_patch_archive=$(get_jboss_patch_archive "${TEMP_DIR}/bundles")
  local jboss_version=$(get_jboss_version "${TEMP_DIR}/bundles")

  if [[ -f $jboss_patch_archive ]]; then
    local startup_wait=30
    local jboss_console_log=jboss-patch-console.log

    echo "Preparing for installation of the JBoss EAP Patch ${jboss_patch_archive}..."
    echo "Staring JBoss EAP Standalone in AdminOnly mode..."

    ${TEMP_DIR}/liferay/jboss-eap-${jboss_version}/bin/standalone.sh --admin-only >$jboss_console_log 2>&1 &

    # Some wait code. Wait till the system is ready
    count=0
    launched=false

    until [ $count -gt $startup_wait ]; do
      grep 'WFLYSRV0025:' $jboss_console_log >/dev/null
      if [ $? -eq 0 ]; then
        launched=true
        break
      fi
      sleep 1
      ((count++))
    done

    if [ $launched = "false" ]; then
      echo "Staring JBoss EAP Standalone in AdminOnly mode...[JBoss EAP did not start correctly. See the log file $jboss_console_log. Exiting]"
      exit 1
    else
      echo "Staring JBoss EAP Standalone in AdminOnly mode...[END]"
    fi

    # Apply the patch
    echo "Applying patch: $jboss_patch_archive..."
    ${TEMP_DIR}/liferay/jboss-eap-${jboss_version}/bin/jboss-cli.sh -c "patch apply ${jboss_patch_archive}"

    # And we can shutdown the system using the CLI.
    echo "Shutting down JBoss EAP..."
    ${TEMP_DIR}/liferay/jboss-eap-${jboss_version}/bin/jboss-cli.sh -c ":shutdown"

    echo "Shutting down JBoss EAP..."

    echo "Preparing for installation of the JBoss EAP Patch ${jboss_patch_archive}...[END]"
  fi
}

function install_security_fix_pack() {
  for temp_file_name in "${1}"/liferay-security-*; do
    if [[ -e ${temp_file_name} ]]; then
      echo "Copy the Liferay Security Fix Pack ${temp_file_name}" in ${TEMP_DIR}/liferay/patching-tool/patches
      cp "${temp_file_name}" ${TEMP_DIR}/liferay/patching-tool/patches
    fi
  done

  if [ "$(ls -A ${TEMP_DIR}/liferay/patching-tool/patches/)" ]; then

    if (${TEMP_DIR}/liferay/patching-tool/patching-tool.sh install); then
      rm -fr ${TEMP_DIR}/liferay/osgi/state/*
      rm -f ${TEMP_DIR}/liferay/patching-tool/patches/*

      echo ""
      echo "Security Fix Pack applied successfully."
    fi
  fi
}

function make_temp_directory() {
  CURRENT_DATE=$(date)

  TIMESTAMP=$(date "${CURRENT_DATE}" "+%Y%m%d%H%M")

  TEMP_DIR=temp-${TIMESTAMP}

  mkdir -p ${TEMP_DIR}

  cp -r template/* ${TEMP_DIR}
}

function pid_8080() {
  local pid=$(lsof -i 4tcp:8080 -sTCP:LISTEN -Fp | head -n 1)

  echo ${pid##p}
}

function prepare_jboss_eap() {
  local jboss_version=$(get_jboss_version "${TEMP_DIR}/bundles")

  # Copy Liferay Module Configuration from template
  cp ${TEMP_DIR}/jboss-eap/${jboss_version}/modules/com/liferay/portal/main/* \
    ${TEMP_DIR}/liferay/jboss-eap/modules/com/liferay/portal/main/

  # Copy JBoss EAP Standalone xml configuration for Liferay
  cp ${TEMP_DIR}/jboss-eap/${jboss_version}/standalone/configuration/* \
    ${TEMP_DIR}/liferay/jboss-eap/standalone/configuration/

  # Copy JBoss EAP Standalone bin configuration for Liferay
  cp ${TEMP_DIR}/jboss-eap/${jboss_version}/bin/* \
    ${TEMP_DIR}/liferay/jboss-eap/bin/

}

function prepare_temp_for_manual_installation() {
  mkdir "${TEMP_DIR}/bundles"

  cp -r ${1}/* "${TEMP_DIR}/bundles"

  local temp_dir_abs=$(get_abs_filename "${TEMP_DIR}")
  local jboss_version=$(get_jboss_version "${TEMP_DIR}/bundles")

  mkdir "${TEMP_DIR}/liferay"
  mkdir "${TEMP_DIR}/liferay/data"
  mkdir "${TEMP_DIR}/liferay/data/license"
  mkdir "${TEMP_DIR}/liferay/logs"
  mkdir "${TEMP_DIR}/liferay/osgi"
  mkdir "${TEMP_DIR}/liferay/config"
  mkdir "${TEMP_DIR}/liferay/deploy"
  mkdir "${TEMP_DIR}/liferay/jboss-eap"

  # Create the symlink for JBoss EAP
  ln -s jboss-eap ${TEMP_DIR}/liferay/jboss-eap-${jboss_version}

  touch "${TEMP_DIR}/liferay/.liferay-home"

  local additional_files
  local additional_files_array=()

  additional_files=$(check_liferay_additional_files "${TEMP_DIR}/bundles")
  additional_files_array=($additional_files)

  if [[ ${#additional_files_array[@]} -lt 3 ]]; then
    echo "Check if all additional files is present in ${TEMP_DIR}/bundles"
    exit 2
  fi

  local liferay_war_archive=$(get_abs_filename "${additional_files_array[0]}")
  local liferay_dependencies_archive=$(get_abs_filename "${additional_files_array[1]}")
  local liferay_osgi_archive=$(get_abs_filename "${additional_files_array[2]}")

  # Extract Application Server
  local as_archive_file=$(get_jboss_archive "${1}")
  local as_archive_file_abs=$(get_abs_filename "${as_archive_file}")
  cd "${temp_dir_abs}/liferay/jboss-eap" || exit 3
  tar -xvf "${as_archive_file_abs}" --strip 1

  if [[ $? -eq 0 ]]; then
    mkdir -p "${temp_dir_abs}/liferay/jboss-eap/modules/com/liferay/portal/main"
    cd "${temp_dir_abs}/liferay/jboss-eap/modules/com/liferay/portal/main" || exit 3
    tar -xvf $(get_abs_filename "${liferay_dependencies_archive}") --strip 1
  fi

  if [[ $? -eq 0 ]]; then
    cd "${temp_dir_abs}/liferay/jboss-eap/standalone/deployments" || exit 3
    touch ROOT.war.dodeploy
    mkdir ROOT.war
    cd ROOT.war || exit 3
    unzip $(get_abs_filename "${liferay_war_archive}")
  fi

  if [[ $? -eq 0 ]]; then
    cd "${temp_dir_abs}/liferay/osgi" || exit 3
    tar -xvf $(get_abs_filename "${liferay_osgi_archive}") --strip 2
  fi

  rm -fr ${temp_dir_abs}/liferay/osgi/state/*

  cd ../../../
}

function prepare_tomcat() {
  local liferay_tomcat_version=$(get_tomcat_version ${TEMP_DIR}/liferay)

  mv ${TEMP_DIR}/liferay/tomcat-${liferay_tomcat_version} ${TEMP_DIR}/liferay/tomcat

  ln -s tomcat ${TEMP_DIR}/liferay/tomcat-${liferay_tomcat_version}

  configure_tomcat

  warm_up_tomcat

  rm -fr ${TEMP_DIR}/liferay/logs/*
  rm -fr ${TEMP_DIR}/liferay/tomcat/logs/*
}

function push_docker_images() {
  if [ "${1}" == "push" ]; then
    for docker_image_tag in "${DOCKER_IMAGE_TAGS[@]}"; do
      docker push ${docker_image_tag}
    done
  fi
}

function start_tomcat() {

  #
  # Increase the available memory for warming up Tomcat. This is needed
  # because LPKG hash and OSGi state processing for 7.0.x is expensive. Set
  # this for all scenarios since it is limited to warming up Tomcat.
  #

  LIFERAY_JVM_OPTS="-Xmx3G"

  local pid=$(pid_8080)

  if [ -n "${pid}" ]; then
    echo ""
    echo "Killing process ${pid} that is listening on port 8080."
    echo ""

    kill -9 ${pid} 2>/dev/null
  fi

  ./${TEMP_DIR}/liferay/tomcat/bin/catalina.sh start

  until $(curl --head --fail --output /dev/null --silent http://localhost:8080); do
    sleep 3
  done

  pid=$(pid_8080)

  ./${TEMP_DIR}/liferay/tomcat/bin/catalina.sh stop

  sleep 30

  kill -9 ${pid} 2>/dev/null

  rm -fr ${TEMP_DIR}/liferay/data/osgi/state
  rm -fr ${TEMP_DIR}/liferay/osgi/state
}

function stat() {
  if [ "$(uname)" == "Darwin" ]; then
    echo $(/usr/bin/stat -f "%z" "${1}")
  else
    echo $(/usr/bin/stat --printf="%s" "${1}")
  fi
}

function test_docker_image() {
  export LIFERAY_DOCKER_IMAGE_ID="${DOCKER_IMAGE_TAGS[0]}"

  ./test_image.sh

  if [ $? -gt 0 ]; then
    echo "Testing failed, exiting."

    exit 2
  fi
}

function warm_up_tomcat() {

  #
  # Warm up Tomcat for older versions to speed up starting Tomcat. Populating
  # the Hypersonic files can take over 20 seconds.
  #

  if [ -d ${TEMP_DIR}/liferay/data/hsql ]; then
    if [ $(stat ${TEMP_DIR}/liferay/data/hsql/lportal.script) -lt 1024000 ]; then
      start_tomcat
    else
      echo Tomcat is already warmed up.
    fi
  fi

  if [ -d ${TEMP_DIR}/liferay/data/hypersonic ]; then
    if [ $(stat ${TEMP_DIR}/liferay/data/hypersonic/lportal.script) -lt 1024000 ]; then
      start_tomcat
    else
      echo Tomcat is already warmed up.
    fi
  fi
}
