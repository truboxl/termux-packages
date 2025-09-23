#!/usr/bin/bash

export TERMUX_SCRIPTDIR
TERMUX_SCRIPTDIR=$(realpath "$(dirname "$0")/..") # Root of repository.

cd "${TERMUX_SCRIPTDIR}" || exit 1

. ${TERMUX_SCRIPTDIR}/scripts/properties.sh
. ${TERMUX_SCRIPTDIR}/scripts/build/termux_download.sh
. ${TERMUX_SCRIPTDIR}/scripts/build/setup/termux_setup_scrcpy.sh

termux_setup_scrcpy

scrcpy --record=sr.mp4
