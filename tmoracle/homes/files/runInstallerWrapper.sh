#!/usr/bin/env bash

set -uex

INSTALLER="${1}"
RESPONSE_FILE="${2}"

${INSTALLER} -waitForCompletion -silent -responseFile ${RESPONSE_FILE}
