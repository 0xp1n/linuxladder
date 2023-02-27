#!/bin/bash

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
###
#   If the --no-report option is selected we only remove the file after the enumeration
#   because is more easy to manage instead of append conditionals through the code
###
report_file_path=report
create_report=true

showHelpPanel() {
    echo -e "A Linux Privilege Escalation enumeration tool to speed up the information gathering focus on productivity\n"
    echo -e  "$yellowColour USAGE:\n $endColour \tlinuxladder [OPTIONS]"
    echo -e "\n  BY DEFAULT THE TOOL CREATES A $report_file_path FILE ON THE ACTUAL DIRECTORY, TO DISABLE THIS BEHAVIOR USE --no-report\n"
    echo -e "\t$greenColour-o <filepath>$endColour  Choose the destination path for the report file"
    echo -e "\t$greenColour  --no-report$endColour Disable the creation of the report file and only show the output in terminal"
    exit 1
}

# Translate wide-format options into short ones
for arg in "$@"; do
  shift
  case "$arg" in
    '--help')      set -- "$@" '-h'   ;;
    '--no-report') set -- "$@" '-n'   ;;
    *)             set -- "$@" "$arg" ;;
  esac
done

# Read user options
while getopts ":o:nh:" arg; do
    case $arg in
        o)
          if [ ! -z $OPTARG ]; then
             report_file_path=$OPTARG
          fi

        ;;
        n)
            create_report=false
        ;;
        h | --help |  *)
            showHelpPanel
        ;;
    esac

done
shift $(expr $OPTIND - 1) # remove options from positional parameters

# Create the report file to fill all the information output after the enumeration
create_report_file() {
    if [ ! -d $(dirname $report_file_path) ]; then
         mkdir -p $(dirname $report_file_path)
    fi

    if [ -f $report_file_path ]; then
        truncate -s 0 $report_file_path
    else
        touch $report_file_path
    fi

}

remove_report_file() {
    if [ $create_report = false ]; then
        find $(dirname $report_file_path) -type f -name "$(basename $report_file_path)" -exec rm {} \;
    fi
}

display_actual_user() {
    echo -e "\nYou're running this tool as $yellowColour$(whoami)$endColour"
    echo -e "$(id)\n"
}

os_information() {
    echo -e "$yellowColour########## [ OS INFORMATION ] ###########$endColour\n" >> $report_file_path

    (cat /proc/version || uname -a ) 1>>"$report_file_path" 2>/dev/null
	lsb_release -a 1>>"$report_file_path" 2>/dev/null
	cat /etc/os-release 1>>"$report_file_path" 2>/dev/null
}

writable_folders_in_path() {
    if [ ! -d /tmp ]; then
        tmp=/dev/shm
    else
        tmp=$(mktemp -d)
    fi

    echo $PATH | sed 's/:/\n/g' > "$tmp/paths"

    echo -e "\n$yellowColour########## [ PATH ENV ] ###########$endColour\n" >> $report_file_path

    while IFS= read -r bin_path; do
        if [ -w $bin_path ]; then
            echo -e  "$bin_path$greenColour is writeable!$endColour $yellowColour[+] Path hijacking potential vulnerability$endColour" >> $report_file_path
        else
            echo -e "$bin_path$redColour is not writeable$endColour" >> $report_file_path
        fi
    done < "$tmp/paths"

    rm -rf "$tmp/paths"
}

credentials_on_env() {
    if [ -n "$(command -v env)" ]; then
        echo -e "\n$yellowColour########## [ ENV VARIABLES FOUND FROM SPECIAL KEYWORDS ] ###########$endColour\n" >> $report_file_path

        (env | grep -iE 'pass|key|cred|vault|api|shell|session|auth|admin|root|ssh') >> $report_file_path
    fi
}

sudo_version() {
    version=$(sudo -V | grep -i "sudo ver" | awk '{print $3}')

    echo -e "\n$yellowColour########## [ SUDO VERSION VULNERABILITY CHECK - SEARCHSPLOIT ] ###########$endColour\n" >> $report_file_path
    echo -e "VERSION: $version\n" >> $report_file_path

    if [ -n "$(command -v searchsploit)" ]; then
       searchsploit "$version" >> $report_file_path
    fi
}


banner
display_actual_user
create_report_file

echo -e "$cyanColour [+] Reading OS information...$endColour\n"
os_information

echo -e "$cyanColour [+] Checking PATH folders writeable permissions... $endColour\n"
writable_folders_in_path

echo -e "$cyanColour [+] Reading system ENV variables to find some sensitive data...\n"
credentials_on_env

echo -e "$cyanColour [+] Reading sudo version and search for exploits...$endColour"
sudo_version

#remove_report_file

echo -e "\n$yellowColour [ LINUX PRIVILEGE ESCALATION SCAN COMPLETED! ] $endColour"
echo -e "\n$yellowColour GIVE SOME LOVE IF YOU LIKED THIS TOOL ON$endColour$blueColour https://github.com/0xp1n/linuxladder$endColour, THANK YOU ANYWAY FOR YOUR SUPPORT!$endColour"

