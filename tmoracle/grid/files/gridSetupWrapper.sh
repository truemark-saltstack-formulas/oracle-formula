#!/usr/bin/env bash

RESPONSE_FILE="${1}"

su - oracle -c "cd {{ home }}; ./gridSetup.sh -waitForCompletion -silent -responseFile ${RESPONSE_FILE}; exit $?"

RETCODE="$?"

if [ "${RETCODE}" == 1 ]; then
  exit 1
else
  exit 0
fi

