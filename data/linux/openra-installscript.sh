#!/bin/bash

# Allow interruption of the script at any time (Ctrl + C)
trap "exit" INT

#*********************************************************************************************************
## VARIABLES USED IN THE SCRIPT
#

# Package name & version
PACKAGE_NAME=openra-bleed-tibsunra2
PACKAGE_VERSION=1

PACKAGE=$PACKAGE_NAME-$PACKAGE_VERSION

# Get our Linux distribution
DISTRO=$(cat /etc/os-release | sed -n '/PRETTY_NAME/p' | grep -o '".*"' | sed -e 's/"//g' -e s/'([^)]*)'/''/g -e 's/ .*//' -e 's/[ \t]*$//')

UBUNTU="Ubuntu"
DEBIAN="Debian"
OPENSUSE="openSUSE"
FEDORA="Fedora"

# Get the current directory
WORKING_DIR=$(pwd)

if [[ $DISTRO =~ $UBUNTU ]] || [[ $DISTRO =~ $DEBIAN ]]; then
# Find out used Linux distribution
	RELEASE=$(lsb_release -d | sed 's/Description:\t//g')

# Check if the used OS is Ubuntu 14.04 LTS/14.10 or Linux Mint
	RELEASE_VERSION=$(lsb_release -r | sed 's/[^0-9]*//g')
	RELEASE_MINT=$(lsb_release -i 2>/dev/null |grep -c "Mint")

# Check for critical build dependencies (especially for Ubuntu 14.04 LTS/14.10 & Linux Mint)
	PKG1_CHECK=$(dpkg-query -W -f='${Status}' libnuget-core-cil 2>/dev/null | grep -c "ok installed")
	PKG2_CHECK=$(dpkg-query -W -f='${Status}' mono-devel 2>/dev/null | grep -c "ok installed")
	PKG3_CHECK=$(dpkg-query -W -f='${Status}' nuget 2>/dev/null | grep -c "ok installed")

# Do we have any OpenRA packages on the system?
	PKG4_CHECK=$(dpkg-query -W -f='${Status}' openra 2>/dev/null | grep -c "ok installed")
	PKG5_CHECK=$(dpkg-query -W -f='${Status}' openra-playtest 2>/dev/null | grep -c "ok installed")
	PKG6_CHECK=$(dpkg-query -W -f='${Status}' openra-bleed 2>/dev/null | grep -c "ok installed")

elif [[ $DISTRO =~ $OPENSUSE ]]; then

# Find out used OpenSUSE version
	RELEASE=$(cat /etc/os-release | sed -n 4p | grep -o '".*"' | sed -e 's/"//g' -e s/'([^)]*)'/''/g -e 's/[ \t]*$//')

# Do we have any OpenRA packages on the system?
	PKG1_CHECK=$(rpm -qa openra | wc -l)
	PKG2_CHECK=$(rpm -qa openra-playtest | wc -l)
	PKG3_CHECK=$(rpm -qa openra-bleed | wc -l)
	
elif [[ $DISTRO =~ $FEDORA ]]; then

# Find out used Fedora version
	RELEASE=$(cat /etc/os-release | sed -n '/PRETTY_NAME/p' | grep -o '".*"' | sed -e 's/"//g' -e s/'([^)]*)'/''/g -e 's/[ \t]*$//')
	
# Do we have any OpenRA packages on the system?
	PKG1_CHECK=$(rpm -qa openra | wc -l)
	PKG2_CHECK=$(rpm -qa openra-playtest | wc -l)
	PKG3_CHECK=$(rpm -qa openra-bleed | wc -l)
fi

# Check for missing RA2 directories.
RA2_MISSINGDIR1="$HOME/openra-master/$PACKAGE/mods/ra2/bits/vehicles"
RA2_MISSINGDIR2="$HOME/openra-master/$PACKAGE/mods/ra2/bits/themes"

# Check if we already have sudo password in memory (timeout/timestamp check)
SUDO_CHECK=$(sudo -n uptime 2>&1|grep "load"|wc -l)

BASH_CHECK=$(ps | grep `echo $$` | awk '{ print $4 }')

bold_in='\e[1m'
line_in='\e[4m'
dim_in='\e[2m'

green_in='\e[32m'
red_in='\e[91m'

out='\e[0m'

#*********************************************************************************************************
## PRE-CHECK
#

# Check if we're using bash or sh to run the script. If bash, OK. If sh, ask user to run the script with bash.

if [ ! $BASH_CHECK = "bash" ]; then
	echo  "
Please run this script using bash (/usr/bin/bash).
	"
	exit 1
fi

# Check if we are root or not. If yes, then terminate the script.

if [[ $UID = 0 ]]; then
	echo -e "\nPlease run this script as a regular user. Do not use root or sudo. Some commands used in the script require regular user permissions.\n"
	exit 1
fi

#If package dir exists already, delete it.

if [ -d "$HOME/openra-master/" ]; then
	rm -rf "$HOME/openra-master"
fi

if [[ $DISTRO =~ $UBUNTU ]] || [[ $DISTRO =~ $DEBIAN ]]; then
#If deb package exists already, delete it.

	if [ -f $HOME/$PACKAGE_NAME*.deb ]; then
		rm -f $HOME/$PACKAGE_NAME*.deb
	fi
elif [[ $DISTRO =~ $OPENSUSE ]] || [[ $DISTRO =~ $FEDORA ]]; then
	if [ -f $HOME/$PACKAGE_NAME*.rpm ]; then
		rm -f $HOME/$PACKAGE_NAME*.rpm
	fi
fi
# Stop execution if we encounter an error
set -e

#*********************************************************************************************************
## PART 1/7
#
## Installation of OpenRA compilation dependencies and user notification message

echo -e "\n$bold_in***Welcome Comrade*** $out\n" 
echo -e "This script compiles and installs OpenRA from source with Tiberian Sun & Red Alert 2.\n
- The script is NOT made by the developers of OpenRA and may contain bugs.
- The script creates an installation package using OpenRA source code and additional Red Alert 2 mod files from Github.\n\nNOTE: As the development of OpenRA & Red Alert 2 continues, this script will likely become unusable some day. Please, feel free to modify it if necessary."

if [[ $DISTRO =~ $UBUNTU ]]; then
	echo -e "$line_in\nThe script has been tested on:\n\nDistribution\t\tStatus$out\nUbuntu 16.04 LTS$green_in\tOK$out\nUbuntu 15.10$green_in\t\tOK$out\nUbuntu 15.04 LTS$green_in\tOK$out\nUbuntu 14.10$green_in\t\tOK$out\nUbuntu 14.04 LTS$green_in\tOK$out\nLinux Mint 17.3$green_in\t\tOK$out\nLinux Mint 17.2$green_in\t\tOK$out\nLinux Mint 17.1$green_in\t\tOK$out\nLinux Mint 16$red_in\t\tFailure$out$dim_in (can't find required packages)$out\n"
elif [[ $DISTRO =~ $DEBIAN ]]; then
	echo -e "$line_in\nThe script has been tested on:\n\nDistribution\t\tStatus$out\nDebian 8.3 $green_in\t\tOK$out\n"
elif [[ $DISTRO =~ $OPENSUSE ]]; then
	echo -e "$line_in\nThe script has been tested on:\n\nDistribution\t\tStatus$out\nOpenSUSE Tumbleweed $green_in\tOK$out\nOpenSUSE Leap 42.1 $green_in\tOK$out\nOpenSUSE 13.2 $green_in\t\tOK$out\nOpenSUSE 13.1 $red_in\t\tFailure$out$dim_in (can't find required packages)$out\n"
elif [[ $DISTRO =~ $FEDORA ]]; then
	echo -e "$line_in\nThe script has been tested on:\n\nDistribution\t\tStatus$out\nFedora 23 $green_in\t\tOK$out\nFedora 22 $green_in\t\tOK$out\nOpenSUSE 13.1 $red_in\t\tFailure$out$dim_in (can't find required packages)$out\n"
fi

echo -e "You are using $RELEASE.\n"
read -r -p "Do you want to continue? [y/N] " response

if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
	sleep 1

	if [[ $DISTRO =~ $UBUNTU ]] || [[ $DISTRO =~ $DEBIAN ]]; then
		echo -e "\nAllright, let's continue. Do you want $bold_in\n\n1.$out manually check which OpenRA build dependencies (packages) will be installed on your system and manually install OpenRA after compilation? $dim_in(manual apt-get + deb packages installation)$bold_in\n2.$out automatically accept the installation of the OpenRA build dependencies during the script execution and automatically install OpenRA after compilation? $dim_in(apt-get with -y option + automatic .deb packages installation)$out\n"
	elif [[ $DISTRO =~ $OPENSUSE ]] || [[ $DISTRO =~ $FEDORA ]]; then
		echo -e "\nAllright, let's continue. Do you want $bold_in\n\n1.$out manually check which OpenRA build dependencies (packages) will be installed on your system and manually install OpenRA after compilation? $dim_in(manual rpm packages installation)$bold_in\n2.$out automatically accept the installation of the OpenRA build dependencies during the script execution and automatically install OpenRA after compilation? $dim_in(automatic installation of rpm packages)$out\n"
	fi
	read -r -p "Please type 1 or 2 (Default: 2): " number
	sleep 1
	if [[ $number -eq 1 ]]; then
		METHOD=''
		echo -e "\nSelected installation method:$bold_in Manual$out"
	else
		if [[ $DISTRO =~ $UBUNTU ]] || [[ $DISTRO =~ $DEBIAN ]] || [[ $DISTRO =~ $FEDORA ]]; then
			METHOD=-y
			echo -e "\nSelected installation method:$bold_in Automatic$out"
		elif [[ $DISTRO =~ $OPENSUSE ]]; then
			METHOD='--non-interactive --no-gpg-checks'
			echo -e "\nSelected installation method:$bold_in Automatic$out"
		fi
	fi

	if [ $SUDO_CHECK -eq 0 ]; then
		if [ -z $METHOD ]; then
			echo -e "\nOpenRA compilation requires that you install some packages first. Your permission for installation is asked (yes/no) everytime it's needed. This script asks for a required root password now, so you don't have to type it multiple times later on while the script is running.\n\nPlease type sudo/root password now.\n" 
		else
			echo -e "\nOpenRA compilation requires that you install some packages first. This script asks for a required root password now, so you don't have to type it multiple times later on while the script is running.\n\nPlease type sudo/root password now.\n"
		fi
		sudo echo -e "\nRoot password OK."
		sleep 1
	else
		true
	fi

## Check if the user is running Ubuntu 14.04 LTS/14.10 or Linux Mint and whether required nuget packages are installed if these Linux versions are being used.
	if [[ $DISTRO =~ $UBUNTU ]]; then
		if [  $RELEASE_VERSION == 1404 ] || [ $RELEASE_VERSION == 1410 ] || [ $RELEASE_MINT -eq 1 ] ; then
			echo -e "\nYou are running Ubuntu 14.04 LTS/14.10 or Linux Mint. We need to check if you have required NuGet packages installed.\nThese packages are not (longer available) from the official repository but they are provided by this package.\n"
			read -r -p "Press ENTER to proceed." enter
			if [ ${#enter} -eq 0 ]; then
				echo -e "$line_in\nChecking NuGet packages$out"
			fi
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
## Check existence of 'nuget', 'libnuget-core-lib' & 'mono-devel' packages on Ubuntu 14.04 LTS/14.10/Linux Mint based system. 

				if [ $PKG2_CHECK -eq 1 ]; then
					echo -e "$green_in\nOK$out - 'mono-devel' found."
				else
					echo -e "$red_in\nWARNING$out - 'mono-devel' not found."
				fi

				if [ $PKG1_CHECK -eq 1 ]; then
					echo -e "$green_in\nOK$out - 'libnuget-core-cil' found."
				else
					echo -e "$red_in\nWARNING$out - 'libnuget-core-cil' not found."
				fi

				if [ $PKG3_CHECK -eq 1 ]; then
					echo -e "$green_in\nOK$out - 'nuget' found."
				else
					echo -e "$red_in\nWARNING$out - 'nuget' not found."
				fi

				if [ ! $PKG2_CHECK -eq 1 ]; then
					echo -e "$red_in\nWARNING$out - NuGet requires 'mono-devel' package which was not found.\n\nInstalling 'mono-devel' now."
					sleep 5
					echo -e "\nUpdating package lists with APT.\n"
					sleep 2
					sudo apt-get update && \
					sudo apt-get $METHOD install mono-devel
				fi

				if [ ! $PKG1_CHECK -eq 1 ]; then
					if [ $number = 1 ]; then
						echo
						read -r -p "Install 'libnuget-core-cil' now? [y/N] " response2
							if [[ $response2 =~ ^([yY][eE][sS]|[yY])$ ]]; then
								sudo dpkg -i ./data/linux/ubuntu/libnuget-core-cil_2.8.5+md59+dhx1-1~getdeb1_all.deb
							else
								echo -e "\nOpenRA installation can't continue. Aborting.\n"
								exit 1
							fi
					else
						sudo dpkg -i ./data/linux/ubuntu/libnuget-core-cil_2.8.5+md59+dhx1-1~getdeb1_all.deb
					fi
				fi

				PKG1_RECHECK=$(dpkg-query -W -f='${Status}' libnuget-core-cil 2>/dev/null | grep -c "ok installed")

				if [ ! $PKG3_CHECK -eq 1 ]; then
					if [ $number = 1 ]; then
						echo
						read -r -p "Install 'nuget' now? [y/N] " response3
							if [[ $response3 =~ ^([yY][eE][sS]|[yY])$ ]]; then
								sudo dpkg -i ./data/linux/ubuntu/nuget_2.8.5+md59+dhx1-1~getdeb1_all.deb
							else
								echo -e "\nOpenRA installation can't continue. Aborting.\n"
								exit 1
							fi
					else
						sudo dpkg -i ./data/linux/ubuntu/nuget_2.8.5+md59+dhx1-1~getdeb1_all.deb
					fi
				fi

				PKG3_RECHECK=$(dpkg-query -W -f='${Status}' nuget 2>/dev/null | grep -c "ok installed")

				if [ $PKG1_RECHECK -eq 1 ] && [ $PKG3_RECHECK -eq 1 ]; then
					echo -e "$green_in\nOK$out - All required NuGet packages are installed."
				else
					echo -e "$red_in\nWARNING$out - Can't find all required NuGet packages. Aborting.\n"
					exit 1
				fi
		else
			true
		fi
	fi
	sleep 2
#-----------------------------------------------------------------------------------------------------------------------------------------------------------

	echo -e "$bold_in\n1/7 ***OpenRA build dependencies***\n$out"
	sleep 2
	if [[ $DISTRO =~ $UBUNTU ]] || [[ $DISTRO =~ $DEBIAN ]]; then
		echo -e "Updating package lists with APT.\n"
		sleep 2
		sudo apt-get update
	fi
	echo -e "Installing required OpenRA build dependencies.\n"
	sleep 4
	if [[ $DISTRO =~ $UBUNTU ]] || [[ $DISTRO =~ $DEBIAN ]]; then
		sudo apt-get $METHOD install git dpkg-dev dh-make mono-devel libfreetype6-dev libopenal-data libopenal1 libsdl2-2.0-0 nuget curl liblua5.1-0-dev zenity xdg-utils build-essential gcc make libfile-fcntllock-perl
		mozroots --import --sync && \
		sudo apt-key update
	elif [[ $DISTRO =~ $OPENSUSE ]]; then
		if [[ ! $RELEASE = "openSUSE Leap 42.1" ]] || [[ ! $RELEASE = "openSUSE Tumbleweed" ]]; then
			sudo zypper $METHOD install rpm-build git mono-devel libfreetype6 libopenal1 libSDL2-2_0-0 curl lua51 liblua5_1 zenity xdg-utils gcc make
			sudo zypper $METHOD install ./data/linux/opensuse/mono-nuget-2.8.5-4.2.noarch.rpm
		else
			sudo zypper $METHOD install rpm-build git mono-devel libfreetype6 libopenal1 libSDL2-2_0-0 mono-nuget curl lua51 liblua5_1 zenity xdg-utils gcc make
		fi
		mozroots --import --sync
	elif [[ $DISTRO =~ $FEDORA ]]; then
		sudo dnf $METHOD install rpm-build git mono-devel freetype-devel openal-soft SDL2 libgdiplus-devel libcurl compat-lua zenity xdg-utils gcc make
		cd /etc/yum.repos.d/
		if [[ $RELEASE = "Fedora 23" ]]; then
			sudo wget http://download.opensuse.org/repositories/games:openra/Fedora_23/games:openra.repo
			sudo dnf $METHOD --best --allowerasing install mono-core nuget
		elif [[ $RELEASE = "Fedora 22" ]]; then
			sudo wget http://download.opensuse.org/repositories/games:openra/Fedora_22/games:openra.repo
			sudo dnf $METHOD --best --allowerasing install mono-core
			if [[ $(uname -m) = "i686" ]];then
				sudo dnf $METHOD install $WORKING_DIR/data/linux/fedora/nuget-2.8.7-0.fc22.i686.rpm
			elif [[ $(uname -m) = "x86_64" ]];then
				sudo dnf $METHOD install $WORKING_DIR/data/linux/fedora/nuget-2.8.7-0.fc22.x86_64.rpm
			fi
		fi
		cd $WORKING_DIR
		mozroots --import --sync
	fi

#*********************************************************************************************************
## PART 2/7
#
## Download the latest OpenRA & Red Alert 2 source files from Github, create build directories to the user's home directory. 
## Once Red Alert 2 source files have been downloaded, move them to the OpenRA parent source directory. 
## Add several missing directories for Red Alert 2.

	echo -e "$bold_in\n2/7 ***Downloading OpenRA source code & Red Alert 2 mod files from Github***\n$out"
	sleep 2
	echo -e "Part 1 (OpenRA source code):\n"

	mkdir -p $HOME/openra-master/{$PACKAGE,ra2} && \
	git clone -b bleed https://github.com/OpenRA/OpenRA.git $HOME/openra-master/$PACKAGE

	echo -e "\nPart 2 (Red Alert 2 mod files):\n"

	git clone -b master https://github.com/OpenRA/ra2.git $HOME/openra-master/ra2 && \
	mv $HOME/openra-master/ra2/OpenRA.Mods.RA2 $HOME/openra-master/$PACKAGE && \
	mv $HOME/openra-master/ra2 $HOME/openra-master/$PACKAGE/mods/

	if [ ! -d "$RA2_MISSINGDIR1" ]; then
		mkdir "$RA2_MISSINGDIR1"
	fi

	if [ ! -d "$RA2_MISSINGDIR2" ]; then
		mkdir "$RA2_MISSINGDIR2"
	fi

	cp ./data/patches/*.patch $HOME/openra-master/

#*********************************************************************************************************
## PART 3/7
#
## Patch several OpenRA source files (Makefile and such) for Tiberian Sun & Red Alert 2

	echo -e "$bold_in\n3/7 ***Preparing OpenRA source files for Tiberian Sun & Red Alert 2***\n$out"
	sleep 2
	for i in $HOME/openra-master/*.patch; do patch -d $HOME/openra-master/$PACKAGE -Np1 --binary < $i; done

# Get version number for Red Alert 2 mod (Github)
RA2_VERSION=git-$(git ls-remote https://github.com/OpenRA/ra2.git | head -1 | sed "s/HEAD//" | sed 's/^\(.\{7\}\).*/\1/')

	sed -i "s/Version: {DEV_VERSION}/Version: $RA2_VERSION/g" $HOME/openra-master/$PACKAGE/mods/ra2/mod.yaml

#*********************************************************************************************************
## PART 4/7
#
## Compile the game

	echo -e "$bold_in\n4/7 ***Starting OpenRA compilation with Tiberian Sun & Red Alert 2***$out"
	sleep 2
	if [[ $DISTRO =~ $UBUNTU ]] || [[ $DISTRO =~ $DEBIAN ]]; then
		cd $HOME/openra-master/$PACKAGE && \
		make version && \
		make dependencies && \
		make all [DEBUG=false]

		echo -e "$bold_in\n5/7 ***Preparing OpenRA deb package. This takes a while. Please wait.***\n$out"
		dh_make --createorig -s -y && \
		echo -e "\noverride_dh_auto_install:\n\tmake install-all install-linux-shortcuts prefix='$HOME/openra-master/$PACKAGE/debian/$PACKAGE_NAME/usr'\n\tsed -i '2s%.*%cd /usr/lib/openra%' '$HOME/openra-master/$PACKAGE/debian/$PACKAGE_NAME/usr/bin/openra'\noverride_dh_usrlocal:\noverride_dh_auto_test:" >> $HOME/openra-master/$PACKAGE/debian/rules && \
		sed -i 's/Depends: ${shlibs:Depends}, ${misc:Depends}/Depends: libopenal1, mono-runtime (>= 2.10), libmono-system-core4.0-cil, libmono-system-drawing4.0-cil, libmono-system-data4.0-cil, libmono-system-numerics4.0-cil, libmono-system-runtime-serialization4.0-cil, libmono-system-xml-linq4.0-cil, libfreetype6, libc6, libasound2, libgl1-mesa-glx, libgl1-mesa-dri, xdg-utils, zenity, libsdl2 | libsdl2-2.0-0, liblua5.1-0/g' $HOME/openra-master/$PACKAGE/debian/control && \
		sed -i 's/<insert up to 60 chars description>/A multiplayer re-envisioning of early RTS games by Westwood Studios\nConflicts: openra, openra-playtest, openra-bleed/g' $HOME/openra-master/$PACKAGE/debian/control && \
		sed -i 's/ <insert long description, indented with spaces>/ ./g' $HOME/openra-master/$PACKAGE/debian/control && \
		dpkg-buildpackage -rfakeroot -b -nc -uc -us

#*********************************************************************************************************
## PART 6/7
#
## Remove temporary OpenRA build files & directories

		echo -e "$bold_in\n6/7 ***Compilation process completed. Moving compiled deb package into '$HOME'***\n$out"
		sleep 2
		mv $HOME/openra-master/$PACKAGE_NAME*.deb $HOME
	elif [[ $DISTRO =~ $OPENSUSE ]] || [[ $DISTRO =~ $FEDORA ]]; then
		echo -e "$bold_in\n5/7 ***Compiling OpenRA rpm package.***\n$out"
		mkdir -p $HOME/openra-master/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
		cp ./data/linux/opensuse/openra.spec $HOME/openra-master/rpmbuild/SPECS/
		cp ./data/linux/opensuse/{GeoLite2-Country.mmdb.gz,thirdparty.tar.gz} $HOME/openra-master/rpmbuild/SOURCES/
		cd $HOME/openra-master
		tar -czf $HOME/openra-master/rpmbuild/SOURCES/$PACKAGE.tar.gz ./$PACKAGE
		cd $WORKING_DIR
        
		rpmbuild --define "_topdir $HOME/openra-master/rpmbuild" -bb --clean $HOME/openra-master/rpmbuild/SPECS/openra.spec

		echo -e "$bold_in\n6/7 ***Compilation process completed. Moving compiled rpm package into '$HOME'***\n$out"
		sleep 2
		mv $HOME/openra-master/rpmbuild/RPMS/noarch/$PACKAGE_NAME*.rpm $HOME
	fi
	echo -e "Removing temporary files."
	rm -rf $HOME/openra-master

#*********************************************************************************************************
## PART 7/7
#
## Install OpenRA

	echo -e "$bold_in\n7/7 ***Starting OpenRA installation process***\n$out"
	sleep 2
	if [[ $DISTRO =~ $UBUNTU ]] || [[ $DISTRO =~ $DEBIAN ]]; then
		if [ $PKG4_CHECK -eq 1 ] || [ $PKG5_CHECK -eq 1 ] || [ $PKG6_CHECK -eq 1 ] ; then
			echo -e "\nCan't install '$PACKAGE_NAME' because of conflicting packages.\nPlease remove previously installed openra package from your system and try again.\nBuilt $PACKAGE_NAME deb package can be found in '$HOME'.\n"

		else
			if [[ $number -eq 1 ]]; then
				read -r -p "Install '$PACKAGE_NAME' now? [y/N] " response4
					if [[ $response4 =~ ^([yY][eE][sS]|[yY])$ ]]; then
						sudo dpkg -i $HOME/$PACKAGE_NAME*.deb
					else
						echo -e "\nPlease install '$PACKAGE_NAME' manually. You find the compiled package in '$HOME'."
						sleep 2
					fi
			else
				sudo dpkg -i $HOME/$PACKAGE_NAME*.deb
			fi
		fi
	elif [[ $DISTRO =~ $OPENSUSE ]] || [[ $DISTRO =~ $FEDORA ]]; then
		if [ $PKG1_CHECK -eq 1 ] || [ $PKG2_CHECK -eq 1 ] || [ $PKG3_CHECK -eq 1 ] ; then
			echo -e "\nCan't install '$PACKAGE_NAME' because of conflicting packages.\nPlease remove previously installed openra package from your system and try again.\nBuilt $PACKAGE_NAME rpm package can be found in '$HOME'.\n"
		else
			if [[ $number -eq 1 ]]; then
				read -r -p "Install '$PACKAGE_NAME' now? [y/N] " response4
					if [[ $response4 =~ ^([yY][eE][sS]|[yY])$ ]]; then
						if [[ $DISTRO =~ $FEDORA ]]; then
							sudo dnf $METHOD --best --allowerasing install $HOME/$PACKAGE_NAME*.rpm
						elif [[ $DISTRO =~ $OPENSUSE ]]; then
							sudo zypper $METHOD install $HOME/$PACKAGE_NAME*.rpm
						fi
					else
						echo -e "\nPlease install '$PACKAGE_NAME' manually. You find the compiled package in '$HOME'."
						sleep 2
					fi
			else
				if [[ $DISTRO =~ $FEDORA ]]; then
					sudo dnf $METHOD --best --allowerasing install $HOME/$PACKAGE_NAME*.rpm
				elif [[ $DISTRO =~ $OPENSUSE ]]; then
					sudo zypper $METHOD install $HOME/$PACKAGE_NAME*.rpm
				fi
			fi
		fi
	fi

#*********************************************************************************************************

else
	echo -e "\nAborted.\n"
fi
