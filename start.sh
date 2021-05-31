#!/bin/bash
#### Description: This is a Bash Script to install and get the first important data for security checking.
#### Written by: Alexander Pietrasch https://github.com/Almapi


LOCALDIR=$(pwd)


# Check for debian based system

function deb-check () {
    if [ ! -f "/etc/debian_version" ];then
        echo "This script is only for deb based systems, at this moment"
        echo "Please let me know, if you need another system @ https://github.com/Almapi"
        exit 1
    fi
}
deb-check


# Define a function to get Yellow Output
yellow_echo () {
  output="$1"
  echo -e "\e[33m${output}\e[0m"

}

red_echo () {
  output="$1"
  echo -e "\e[31m${output}\e[0m"

}

green_echo () {
  output="$1"
  echo -e "\e[92m${output}\e[0m"

}


function pre-script () {

# Read Users input to define simple variables
echo ""
echo ""
echo "Enter the Domain you want to check [without protocol]:" 
read domain 

yellow_echo "\nSome checks are not allowed to use on foreign Domains or Servers!!!"
yellow_echo "Are you sure, you have the permission to run this script against the domain: \e[31m${domain}\e[0m [Y/n]"
read permission

if [ ! "${permission}" = "y" ]; then
    yellow_echo "Please use this script only for your Domains and Server"
    yellow_echo "It is to help you against cyber attacks"
    exit 1
fi

}


# Create a function for sublist3r

function execute-sublist3r () {

    # Create a temporary directory for latest version for sublist3r
    TEMPDIR=$(mktemp -d -t sublist-tmp-XXXXXXXXX)

    # Clone latest version of sublist3r to this directory 
    git clone https://github.com/aboul3la/Sublist3r.git ${TEMPDIR}
    cd ${TEMPDIR}
    
    # Install sublist3r
    pip install -r requirements.txt

    # Executes sublist3r with python and create a file with the output in this main path of this repository
    python sublist3r.py -n -d ${domain} -o ${LOCALDIR}/subdomain-list-${domain}.txt

    # Remove the temporary directory
    rm -rf ${TEMPDIR}
}


# Get the IP Address and information about the hosting

function get-org-information () {

    local loc_dom_file=${domain}-ip.txt
    local loc_host_file=${domain}-whois.txt
    local loc_mail_file=${domain}-mailserver.txt

    echo "This are the IP addresses of ${domain}:" > ${loc_dom_file}
    dig @8.8.8.8 ${domain} A +short >> ${loc_dom_file} 
    echo "" >> ${loc_dom_file}

    for ip in $(tail +2 ${loc_dom_file})
    do
            echo -e "The IPs are hosted by:" > ${loc_host_file}
            whois $ip | grep -i org|grep -i name >> ${loc_host_file}
    done
    echo "" >> ${loc_host_file}

    echo -e "The Mailserver is:" > ${loc_mail_file}
    dig @8.8.8.8 ${domain} MX +short >> ${loc_mail_file}
    echo "" >> ${loc_mail_file}

}


function check-ports () {
    yellow_echo "Do you wanna check some ports of the ip addresses? [N/y]"
    
    read var

    if [ "${var}" = "y" ]
    then
        echo "Which IP do you want do scan?"
        tail ${domain}-ip.txt
        echo "One of theese?"
        read NMAPIP
        
        echo "Do you wann a fast/quick Scan or check all (takes more time) open ports? [N/y]"
        read var
        if [ "${var}" = "y" ]
        then
            nmap ${NMAPIP}
        else 
            nmape -Pn ${NMAPIP} -p-
        fi
    fi
}



pre-script
check-ports



get-org-information 
execute-sublist3r





green_echo "The checks run succesfull\n"
