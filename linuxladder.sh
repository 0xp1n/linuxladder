#!/usr/bin/env bash

set -u

CURRENT_DIR=$(pwd)


# ANSII ESCAPE CODE COLOURS
greenColour='\033[0;32m'
redColour='\033[0;31m'
blueColour='\033[0;34m'
yellowColour='\033[1;33m'
purpleColour='\033[0;35m'
cyanColour='\033[0;36m'
grayColour='\033[0;37m'

endColour='\033[0m'

banner() {
	cat << "EOF"

 |    _ _|  \  | |   |\ \  / |        \    __ \  __ \  ____|  _ \
 |      |    \ | |   | \  /  |       _ \   |   | |   | __|   |   |
 |      |  |\  | |   |    \  |      ___ \  |   | |   | |     __ <
_____|___|_| \_|\___/  _/\_\_____|_/    _\____/ ____/ _____|_| \_\
EOF
}

report_file_path=report.dat

create_report_file() {

    if [ ! -d $(dirname $report_file_path) ]; then
      mkdir -p $(dirname $report_file_path)
  fi

  if [ ! -f $(basename $report_file_path) ]; then
      touch $(basename $report_file_path)
  fi
}

os_information() {
	(cat /proc/version || uname -a ) 1>>"$report_file_path" 2>/dev/null
	lsb_release -a 1>>"$report_file_path" 2>/dev/null
	cat /etc/os-release 1>>"$report_file_path" 2>/dev/null
}

banner
create_report_file

echo -e "$yellowColour########## [ OS INFORMATION ] ###########$endColour" >> $report_file_path
os_information
echo -e "$yellowColour#########################################$endColour" >> $report_file_path
