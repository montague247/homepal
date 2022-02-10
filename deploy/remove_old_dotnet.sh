#!/usr/bin/env bash
# Copyright (c) Dirk Helbig. All rights reserved.
#

# Stop script on NZEC
set -e
# Stop script if unbound variable found (use ${var:-} if intentional)
set -u
# By default cmd1 | cmd2 returns exit code of cmd2 regardless of cmd1 success
# This is causing it to fail
set -o pipefail

if [[ "$OSTYPE" == "darwin"* ]]; then
  RED="\033[1;31m"
  GREEN="\033[1;32m"
  CYAN="\033[1;36m"
  NOCOLOR="\033[0m"
else
  RED="\033[0;31m"
  GREEN="\033[0;32m"
  CYAN="\033[0;36m"
  NOCOLOR="\033[0m"
fi

function Remove() {
	local VERSION=$1
	local TARGET_PATH=$2
	local NAME=$3

        echo -ne "Remove ${NAME} version ${VERSION} in path ${TARGET_PATH}..."

	if sudo rm -rf ${TARGET_PATH}/${VERSION}; then
		echo -e "${GREEN}OK${NOCOLOR}"
	else
		echo -e "${RED}ERROR${NOCOLOR}"
	fi
}

function RemoveVersionPathLine() {
	local LINE=$1
	local NAME=$2

	local VERSION=${LINE% *}
	local TARGET_PATH=${LINE##* }
	TARGET_PATH=${TARGET_PATH##*\[}
	TARGET_PATH=${TARGET_PATH%\]*}

	Remove ${VERSION} ${TARGET_PATH} ${NAME}

	VERSION=NuGetFallbackFolder

	if [ -d ${TARGET_PATH}/${VERSION} ]; then
		Remove ${VERSION} ${TARGET_PATH} ${NAME}
	fi
}

dotnet --list-sdks > remove_old_dotnet-sdks.txt

LAST_LINE=""

while IFS= read -r LINE; do
        if [ ! -z "${LAST_LINE}" ]; then
                RemoveVersionPathLine ${LAST_LINE} "SDK"
        fi

        LAST_LINE="${LINE}"
done < remove_old_dotnet-sdks.txt

if [ ! -z "${LAST_LINE}" ]; then
        VERSION=${LAST_LINE% *}
        echo -e "Latest SDK version: ${CYAN}${VERSION}${NOCOLOR}"
fi

dotnet --list-runtimes > remove_old_dotnet-runtimes.txt
LAST_TYPE=""

while IFS= read -r LINE; do
	TYPE=${LINE% *}
	TYPE=${TYPE% *}

	if [ ! "${LAST_TYPE}" = "${TYPE}" ]; then
		if [ "${LAST_TYPE}" = "Microsoft.AspNetCore.All" ] && [ "${TYPE}" = "Microsoft.AspNetCore.App" ]; then
			RemoveVersionPathLine "${LAST_LINE}" "${LAST_TYPE} runtime"
			LAST_TYPE=""
		fi

		if [ ! -z "${LAST_TYPE}" ]; then
        		VERSION=${LAST_LINE% *}
        		echo -e "Latest ${LAST_TYPE} runtime version: ${CYAN}${VERSION}${NOCOLOR}"
		fi

		LAST_LINE=""
	fi

	LAST_TYPE=${TYPE}
	LINE=${LINE#* }

        if [ ! -z "${LAST_LINE}" ]; then
		RemoveVersionPathLine "${LAST_LINE}" "${TYPE} runtime"
        fi

        LAST_LINE="${LINE}"
done < remove_old_dotnet-runtimes.txt

if [ ! -z "${LAST_TYPE}" ]; then
	VERSION=${LAST_LINE% *}
	echo -e "Latest ${LAST_TYPE} runtime version: ${CYAN}${VERSION}${NOCOLOR}"
fi

dotnet --info
