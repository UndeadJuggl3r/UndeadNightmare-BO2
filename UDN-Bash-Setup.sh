#Script Console Colors
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
on_red=$(tput setab 1)
on_green=$(tput setab 2)
on_magenta=$(tput setab 5)
bold=$(tput bold)
standout=$(tput smso)
normal=$(tput sgr0)
alert=${white}${on_red}
title=${standout}
repo_title=${black}${on_green}
message_title=${white}${on_magenta}
currentwd=$(pwd)

# intro function (1)
# shellcheck disable=2005,2312
function _intro() {
	DISTRO=$(lsb_release -is)
	CODENAME=$(lsb_release -cs)
	SETNAME=$(lsb_release -rc)
	echo
	echo
	echo "[${repo_title}Plutonium T6${normal}] ${title} Server Installation ${normal}  "
	echo
	echo "   ${title}              Heads Up!              ${normal} "
	echo "   ${message_title}  Installer only works with the following  ${normal} "
	echo "   ${message_title}  Ubuntu 20.04 ${normal} "
	echo
	echo
	echo "${green}Checking distribution ...${normal}"
	if [[ ! -x /usr/bin/lsb_release ]]; then
		echo "It looks like you are running ${DISTRO}, which is not supported by installer."
		echo "Exiting..."
		exit 1
	fi
	echo "$(lsb_release -a)"
	echo
	if [[ ! "${DISTRO}" =~ ("Ubuntu") ]]; then
		echo "${DISTRO}: ${alert} It looks like you are running ${DISTRO}, which is not supported by QuickBox ${normal} "
		echo 'Exiting...'
		exit 1
	elif [[ ! "${CODENAME}" =~ ("focal") ]]; then
		echo "Oh drats! You do not appear to be running a supported ${DISTRO} release."
		echo "${bold}${SETNAME}${normal}"
		echo 'Exiting...'
		exit 1
	fi
}

# check if root function (2)
function _checkroot() {
	if [[ ${EUID} != 0 ]]; then
		echo 'This script must be run with root privileges.'
		echo 'Exiting...'
		exit 1
	fi
	echo "${green}Congrats! You're running as root. Let's continue${normal} ... "
	echo
}

# setting system hostname function (5)
# shellcheck disable=2162
function _hostname() {
	echo -ne "Please enter a hostname for this server (${bold}Hit ${standout}${green}ENTER${normal} to make no changes${normal}): "
	read input
	if [[ -z ${input} ]]; then
		echo "No hostname supplied, no changes made!!"
	else
		hostname ${input}
		echo "${input}" >/etc/hostname
		echo "127.0.0.1 ${input}" >/etc/hosts
		echo "Hostname set to ${input}"
	fi
	echo
}

function _checkinsDir() 
{	
    echo -e "1) /t6/"
	echo -e "2) /home/"${USER}"/t6"
	echo -e "3) Custom install location"
    echo -ne "${bold}${green}Where would you like to install Plutonium T6 Server?"
    read installDir
    case $installDir in
    1 | "")
        installDirectory="/t6/"
        ;;
    2) installDirectory="/home/"$USER"/t6"
        ;;
    3) echo -ne "Please enter the custom location you would like to use for Plutonium T6 Server?"
        read input
        if [[ -z ${input} ]]; then
		echo "No location supplied, no changes made!"
	else
        installDirectory=${input}
        ;;
}

function _askcontinue() {
	echo
	echo "Press ${standout}${green}ENTER${normal} when you're ready to begin or ${standout}${red}Ctrl+Z${normal} to cancel"
	read input
	echo
}

# ask user for public IP conf (12)
apt-get install -y net-tools
function _askpubIP() {
	local DEFAULTIP
	DEFAULTIP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	echo -ne "${bold}${yellow}Please, write your public server IP (used for ftp)${normal} (Default: ${green}${bold}${DEFAULTIP}${normal}) "
	read input
	if [[ -z "${input}" ]]; then
		IP=${DEFAULTIP}
	else
		IP=${input}
	fi

	echo
}

function _wineSetup() {
    cd $installDirectory
    apt update && apt -y full-upgrade
	apt-get install -y software-properties-common p7zip-full zip
    dpkg --add-architecture i386
    wget -nc https://dl.winehq.org/wine-builds/winehq.key
    apt-key add winehq.key
    add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main'
    apt update
    apt install -y --install-recommends winehq-stable
    rm winehq.key
}

function _dotNetSetup() {
    cd $installDirectory
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    apt update; \
    apt install -y apt-transport-https && \
    apt update && \
    apt install -y dotnet-sdk-6.0
    apt update; \
    apt install -y apt-transport-https && \
    apt update && \
    apt install -y aspnetcore-runtime-3.1
}

function _wineinitSetup() {
    echo -e 'export WINEPREFIX=~/.wine\nexport WINEDEBUG=fixme-all\nexport WINEARCH=win64' >> ~/.bashrc
    source ~/.bashrc
    winecfg
    sleep 10
}

function _unZipReq() {
	sudo mv $currentwd"/T6-Server-IW4M-Files.zip" $installDirectory
}
