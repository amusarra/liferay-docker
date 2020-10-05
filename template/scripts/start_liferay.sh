#!/bin/bash

function main() {
  echo ""
  echo "[LIFERAY] Starting ${LIFERAY_PRODUCT_NAME}. To stop the container with CTRL-C, run this container with the option \"-it\"."
  echo ""

  if [ "${APPLICATION_SERVER}" == "jboss-eap" ]; then
    if [ "${LIFERAY_JPDA_ENABLED}" == "true" ]; then
      ${LIFERAY_HOME}/jboss-eap-7.2.0/bin/standalone.sh -b 0.0.0.0 --debug ${JPDA_ADDRESS}
    else
      ${LIFERAY_HOME}/jboss-eap-7.2.0/bin/standalone.sh -b 0.0.0.0
    fi
  else
    if [ "${LIFERAY_JPDA_ENABLED}" == "true" ]; then
      ${LIFERAY_HOME}/tomcat/bin/catalina.sh jpda run
    else
      ${LIFERAY_HOME}/tomcat/bin/catalina.sh run
    fi
  fi
}

main
