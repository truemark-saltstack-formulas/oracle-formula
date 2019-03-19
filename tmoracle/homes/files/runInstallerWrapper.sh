#!/usr/bin/env bash

INSTALLER="${1}"
RESPONSE_FILE="${2}"

${INSTALLER} -waitForCompletion -silent -responseFile ${RESPONSE_FILE}
RETCODE=$?

if [[ "${RETCODE}" == 6 ]]; then
  exit 0
fi
exit ${RETCODE}
