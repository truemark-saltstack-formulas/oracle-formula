#!/usr/bin/env bash

set -uex

ulimit -n 65536
ulimit -u 16384

INSTALLER="${1}"
RESPONSE_FILE="${2}"

${INSTALLER} -waitForCompletion -silent -responseFile ${RESPONSE_FILE}
