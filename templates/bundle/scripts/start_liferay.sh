#!/bin/bash

function main {
	echo ""
	echo "[LIFERAY] Starting ${LIFERAY_PRODUCT_NAME}. To stop the container with CTRL-C, run this container with the option \"-it\"."
	echo ""

	if [ "${LIFERAY_THREAD_DUMP_PROBE_ENABLED}" == "true" ]
	then
		cat "${LIFERAY_THREAD_DUMP_DIRECTORY}"/*.tdump

		rm "${LIFERAY_THREAD_DUMP_DIRECTORY}"/*.tdump
	fi

  if [ "${APPLICATION_SERVER}" == "jboss-eap" ]; then
    if [ "${LIFERAY_JPDA_ENABLED}" == "true" ]; then
      ${LIFERAY_HOME}/jboss-eap/bin/standalone.sh -b 0.0.0.0 --debug ${JPDA_ADDRESS}
    else
      ${LIFERAY_HOME}/jboss-eap/bin/standalone.sh -b 0.0.0.0
    fi
  else
	if [ "${LIFERAY_JPDA_ENABLED}" == "true" ]
	then
		exec "${LIFERAY_HOME}"/tomcat/bin/catalina.sh jpda run
	else
		exec "${LIFERAY_HOME}"/tomcat/bin/catalina.sh run
	fi
  fi
}

main
