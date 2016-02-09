#!/bin/bash

##-------------------------------------------------------------
# Allow interruption of the script at any time (Ctrl + C)
trap "exit" INT

##-------------------------------------------------------------
# Check if we're using bash or sh to run the script. If bash, OK. If sh, ask user to run the script with bash.

BASH_CHECK=$(ps | grep `echo $$` | awk '{ print $4 }')

if [ ! $BASH_CHECK = "bash" ]; then
	echo  "
Please run this script using bash (/usr/bin/bash).
	"
	exit 1
fi

##-------------------------------------------------------------
# Check if we are root or not. If yes, then terminate the script.

if [[ $UID = 0 ]]; then
	echo -e "\nPlease run this script as a regular user. Do not use root or sudo. Some commands used in the script require regular user permissions.\n"
	exit 1
fi

##-------------------------------------------------------------
# Get our current directory
WORKING_DIR=$(pwd)

# Get our Linux distribution
DISTRO=$(cat /etc/os-release | sed -n '/PRETTY_NAME/p' | grep -o '".*"' | sed -e 's/"//g' -e s/'([^)]*)'/''/g -e 's/ .*//' -e 's/[ \t]*$//')

ARCH="Arch"
UBUNTU="Ubuntu"
DEBIAN="Debian"
OPENSUSE="openSUSE"
FEDORA="Fedora"

##-------------------------------------------------------------
#Post-installation instructions

bold_in='\e[1m'
out='\e[0m'
PACKAGEMANAGER_INSTALL=1
PACKAGEMANAGER_REMOVE=1
PACKAGE_NAME=1
INSTALL_NAME=1

function endtext() {
OPENRA_GITVERSION=git-$(git ls-remote https://github.com/OpenRA/OpenRA.git | head -1 | sed "s/HEAD//" | sed 's/^\(.\{7\}\).*/\1/')
RA2_GITVERSION=git-$(git ls-remote https://github.com/OpenRA/ra2.git | head -1 | sed "s/HEAD//" | sed 's/^\(.\{7\}\).*/\1/')

echo -e  "\n***OpenRA compilation script completed.\nPlease see further instructions below.***"
sleep 2
echo -e "$bold_in\n***MANUAL INSTALLATION***$out\n\nInstall OpenRA by typing '$PACKAGEMANAGER_INSTALL $HOME/$PACKAGE_NAME' (without quotations) in a terminal window."
sleep 4
echo -e "$bold_in\n***TIBERIAN SUN & RED ALERT 2 - HOWTO***$out\n\nTO PLAY TIBERIAN SUN: Launch the game and download the required asset files from the web when the game asks you to do so.\n\nTO PLAY RED ALERT 2: You must install language.mix, multi.mix, ra2.mix and theme.mix into '$HOME/.openra/Content/ra2/' folder. You find these files from original RA2 installation media (CD's):\n\n-theme.mix, multi.mix = RA2 CD Root folder\n-ra2.mix, language.mix = RA2 CD Root/INSTALL/Game1.CAB (inside that archive file)$bold_in\n\n***LAUNCHING OPENRA***$out\n\nTo launch OpenRA, simply type 'openra' (without quotations) in your terminal or use a desktop shortcut file.$bold_in\n\n***UNINSTALLATION***$out\n\nIf you want to remove OpenRA, just type '$PACKAGEMANAGER_REMOVE $INSTALL_NAME' (without quotations)\n\nYou can find package of $INSTALL_NAME in '$HOME' for further usage.$bold_in\n\n***MULTIPLAYER***$out\n\nIt's recommended to build OpenRA using exactly same GIT source files for multiplayer usage to minimize possible version differences/conflicts between players. Please make sure all players have exactly same git versions of their in-game mods (RA, CNC, D2K, TS, RA2). Version numbers are formatted like 'git-e0d7445' etc. and can be found in each mod description in the mod selection menu.\n\nFor this compilation, the version numbers are as follows:\nOpenRA version: $OPENRA_GITVERSION\nRA2 version: $RA2_GITVERSION\n\nHave fun!\n"
}

##-------------------------------------------------------------
# If we're running Arch Linux, then execute this
if [[ $DISTRO =~ "$ARCH" ]]; then

	echo -e "\nYou are about to install OpenRA with Tiberian Sun & Red Alert 2.\n"
	read -r -p "Do you want to continue? [y/N] " response
		if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  	  echo -e "\nStarting OpenRA compilation process.\n"
		sleep 2
		cp ./data/patches/*.patch ./data/linux/arch_linux/
		cd ./data/linux/arch_linux
		updpkgsums
		makepkg -c
		mv *.tar.xz $HOME 

		PACKAGEMANAGER_INSTALL='sudo pacman -U'
		PACKAGEMANAGER_REMOVE='sudo pacman -Rs'
		INSTALL_NAME=$(sed -n '/pkgname/{p;q;}' ./data/linux/arch_linux/PKGBUILD | sed -n 's/^pkgname=//p')
		PACKAGE_NAME=$(find $HOME -maxdepth 1 -type f -iname "$INSTALL_NAME*.tar.xz" | sed -e 's/.*\///')
    
		rm -r */
		rm ./*.patch
		cd $WORKING_DIR

		if [[ $PACKAGE_NAME =~ '^[0-9]+$' ]]; then 
			exit 1
		else
			endtext
 		   	exit 1
		fi

		else
 		   echo -e "\nCancelling OpenRA installation.\n"
 	 	  exit 1
		fi
fi

##-------------------------------------------------------------
# If we're running Ubuntu or Linux Mint or Debian, then execute this
if [[ $DISTRO =~ "$UBUNTU" ]] || [[ $DISTRO =~ "$DEBIAN" ]]; then

	if [[ $DISTRO =~ "$DEBIAN" ]]; then
		if [[ $(dpkg-query -W sudo 2>/dev/null | wc -l) -eq 0 ]]; then
			echo -e "\Please install sudo and add your username to sudo group.\nRun the following commands:\nsu root\nadduser <username> sudo\n\nRe-run this script again then.\nExiting now."
			exit 1
		fi
	fi

	bash ./data/linux/openra-installscript.sh

	PACKAGEMANAGER_INSTALL='sudo dpkg -i'
	PACKAGEMANAGER_REMOVE='sudo apt-get purge --remove'
	INSTALL_NAME=$(sed -n '/PACKAGE_NAME/{p;q;}' ./data/linux/openra-installscript.sh | sed -n 's/^PACKAGE_NAME=//p')
	PACKAGE_NAME=$(find $HOME -maxdepth 1 -type f -iname "$INSTALL_NAME*.deb" | sed -e 's/.*\///')
  
	if [[ $PACKAGE_NAME =~ '^[0-9]+$' ]]; then 
		exit 1
	else
		endtext
    	exit 1
	fi

	exit 1
fi

##-------------------------------------------------------------
# If we're running OpenSUSE or Fedora, then execute this
if [[ $DISTRO =~ "$FEDORA" ]] || [[ $DISTRO =~ "$OPENSUSE" ]]; then

	bash ./data/linux/openra-installscript.sh

	if [[ $DISTRO =~ "$OPENSUSE" ]]; then
		PACKAGEMANAGER_INSTALL='sudo zypper install'
		PACKAGEMANAGER_REMOVE='sudo zypper remove'
	elif [[ $DISTRO =~ "$FEDORA" ]]; then
		PACKAGEMANAGER_INSTALL='sudo dnf install'
		PACKAGEMANAGER_REMOVE='sudo dnf remove'
	fi
	INSTALL_NAME=$(sed -n '/PACKAGE_NAME/{p;q;}' ./data/linux/openra-installscript.sh | sed -n 's/^PACKAGE_NAME=//p')
	PACKAGE_NAME=$(find $HOME -maxdepth 1 -type f -iname "$INSTALL_NAME*.rpm" | sed -e 's/.*\///')
  
	if [[ $PACKAGE_NAME =~ '^[0-9]+$' ]]; then
		exit 1
	else
		endtext
    	exit 1
	fi

	exit 1
fi

##-------------------------------------------------------------
# If we don't have any of the supported distributions
if [[ ! $DISTRO =~ "$ARCH" ]] || [[ ! $DISTRO =~ "$UBUNTU" ]] || [[ ! $DISTRO =~ "$DEBIAN" ]] || [[ ! $DISTRO =~ "$OPENSUSE" ]] || [[ ! $DISTRO =~ "$FEDORA" ]]; then
	echo "
Your Linux Distribution is not supported. Please consider making a new OpenRA installation script for it.
Supported distributions are: Ubuntu, Linux Mint, Debian, OpenSUSE, Fedora and Arch Linux.
"
	exit 1
fi
