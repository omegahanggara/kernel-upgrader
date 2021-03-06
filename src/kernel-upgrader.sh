#!/bin/bash

# Variable
currentKernel=$(uname -r)
totalProcessor=$(nproc)
latestKernel=
urlLatestKernel=
linuxType=$(lsb_release --short --id)

# Function
cin() {
	if [ "$1" == "action" ] ; then output="\e[01;32m[>]\e[00m" ; fi
	if [ "$1" == "info" ] ; then output="\e[01;33m[i]\e[00m" ; fi
	if [ "$1" == "warning" ] ; then output="\e[01;31m[w]\e[00m" ; fi
	if [ "$1" == "error" ] ; then output="\e[01;31m[e]\e[00m" ; fi
	output="$output $2"
	echo -en "$output"
}
 
cout() {
	if [ "$1" == "action" ] ; then output="\e[01;32m[>]\e[00m" ; fi
	if [ "$1" == "info" ] ; then output="\e[01;33m[i]\e[00m" ; fi
	if [ "$1" == "warning" ] ; then output="\e[01;31m[w]\e[00m" ; fi
	if [ "$1" == "error" ] ; then output="\e[01;31m[e]\e[00m" ; fi
	output="$output $2"
	echo -e "$output"
}

function checkRoot()
{
	if [[ $(whoami) != "root" ]]; then
		cout error "You don't have root privilege!"
		cout action "Quiting..."
		sleep 2
		exit 1
	fi
}

function interrupt()
{
	echo -e "\n"
	cout error "CAUGHT INTERRUPT SIGNAL!!!"
	askToQuit=true
	while [[ $askToQuit == "true" ]]; do
		cin info "Do you really want to exit? (Y/n) "
		read answer
		if [[ $answer == *[Yy]* ]] || [[ $answer == "" ]]; then
			cout action "Quiting"
			exit 0
		elif [[ $answer == *[Nn]* ]]; then
			cout action "Rock on..."
			askToQuit=false
		fi
	done
}

function checkInternetConnection()
{
	cout action "Checking Internet Connection..."
	sleep 1
	command -v dig > /dev/null 2>&1
	if [[ $? = 0 ]]; then
		dig www.google.com +time=3 +tries=1 @8.8.8.8 > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			cout info "Good, you have Internet Connection..."
			latestKernel=$(curl https://www.kernel.org/ -s | sed -n "/<td id=\"latest_link\">/,/<\/td>/p" | sed -n -e 's/.*<a.*>\(.*\)<\/a>.*/\1/p');
			urlLatestKernel=$(echo "https://www.kernel.org$(curl https://www.kernel.org/ -s | grep $latestKernel | grep downloadarrow | awk -F "<" {'print $2'} | sed "s/a href\=\".\|\">//g")")
		else
			cout error "You don't have Internet Connection!"
			sleep 1
			cout info "This script requiring Internet Connection!"
			sleep 1
			cout info "Make sure you have Internet Connection, then execute this script again"
			sleep 1
			cout action "Quiting..."
			sleep 2
			exit 1
		fi
	fi
}

function checkCurrentKernel()
{
	cout action "Checking your current kernel version..."
	sleep 1
	cout info "You current kernel version is $currentKernel"
	sleep 1
}

function checkLatestKernel()
{
	cout action "Checking available latest kernel on kernel.org..."
	sleep 1
	cout info "Latest kernel version is $latestKernel"
	sleep 1
}

function getURL()
{
	cout action "Finding download link..."
	sleep 1
	cout info "Found download link at $urlLatestKernel"
	sleep 1
}

function checkLinuxType()
{
	cout action "Checking your Linux type..."
	sleep 2
	cout info "Your Linux type is $linuxType"
}

function checkDependencies()
{
	if [[ $linuxType == "arch" ]]; then
		cout info "Under maintenance..."
		sleep 1
	else
		cout action "Checking dependencies..."
		sleep 1
		cout action "Checking build-essential..."
		sleep 1
		if [[ $(dpkg -l | grep ii | grep build-essential | awk {'print $2'}) == "" ]]; then
			cout warning "build-essential is not installed yet!"
			cout action "Installing build-essential"
			cmd="apt-get install build-essential --yes; sleep 2"
			openTerminal > /dev/null 2>&1
			cout info "Done..."
			sleep 1
		else
			cout info "Found build-essential."
		fi
		cout action "Checking fakeroot..."
		sleep 1
		if [[ $(dpkg -l | grep ii | grep fakeroot | awk {'print $2'}) == "" ]]; then
			cout error "fakeroot is not installed yet!"
			cout action "Installing fakeroot..."
			cmd="apt-get install fakeroot --yes; sleep 2"
			openTerminal > /dev/null 2>&1
			cout info "Done..."
			sleep 1
		else
			cout info "Found fakeroot."
		fi
	fi
}

function setTerminal()
{
	cout action "Setup your default terminal..."
	sleep 1
	which terminator > /dev/null
	if [[ $(echo $?) -eq 0 ]]; then
		terminal=terminator
		cout info "Setup terminator as your terminal..."
	else
		cout error "Terminator not found! Finding another one..."
		sleep 1
		which gnome-terminal > /dev/null
		if [[ $(echo $?) -eq 0 ]]; then
			terminal=gnome-terminal
			cout info "Setup gnome-terminal as your terminal..."
		else
			cout error "gnome-terminal not found! Finding another one..."
			sleep 1
			which konsole > /dev/null
			if [[ $(echo $?) -eq 0 ]]; then
				terminal=konsole
				cout info "Setup konsole as your terminal..."
			else
				cout error "konsole not found! Finding another one..."
				which xterm > /dev/null
				if [[ $(echo $?)  -eq 0 ]]; then
					terminal=xterm
					cout info "Setup xterm as your terminal..."
				else
					cout error "xterm not found!"
					if [[ $terminal == "" ]]; then
						cout error "Looks like you don't have any terminal installed on your system. Make sure you have one of them, them execute this script again."
						cout action "Quiting..."
						sleep 2
						exit 1
					fi
				fi
			fi
		fi
	fi
}

function openTerminal()
{
	terminalCMD=$($terminal -e "$cmd")
}

function testTerminal()
{
	cout action "Testing your terminal..."
	sleep 1
	cmd="whoami; sleep 2"
	openTerminal > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		cout info "Looks good..."
		sleep 1
	else
		cout error "Looks not good... It's OK tho, but you may experience some problems on installation..."
	fi
}

function createDirectory()
{
	cout action "Checking kernel directory on your home folder..."
	sleep 1
	if [[ -d ~/kernel ]]; then
		cout info "Directory is found!"
		sleep 1
		askToDelete=true
		while [[ $askToDelete == "true" ]]; do
		cout info "Do you want to keep it? (Y/n)"
		cin error "WARNING! Pressing n will delete whole folder! "
		read answerToDelete
		if [[ $answerToDelete == *[Yy]* ]] || [[ $answerToDelete == "" ]]; then
			cout action "Keeping..."
			sleep 1
			askToDelete="false"
		elif [[ $answerToDelete == *[Nn]* ]]; then
			cout action "Delete whole folder..."
			sleep 1
			rm -rfv ~/kernel
			sleep 1
			cout action "Create a new one..."
			sleep 1
			mkdir ~/kernel
			askToDelete="false"
		else
			cout error "Wrong statement!"
		fi
		done
	else
		cout error "Directory not found!"
		sleep 1
		cout action "Creating kernel directory on your home folder..."
		sleep 1
		mkdir ~/kernel
	fi
}

function checkKernelSourceFile()
{
	sleep 1
	cout action "Checking linux-$latestKernel.tar.xz in ~/kernel directory."
	fileIsExist=false
	while [[ $fileIsExist == "false" ]]; do
	if [[ -f ~/kernel/linux-$latestKernel.tar.xz ]]; then
		cout info "You have the file source."
		fileIsExist=true
	else
		cout warning "You don't have linux-$latestKernel.tar.xz in ~/kernel directory!"
		sleep 1
		cout info "Renaming file may cause this error."
		sleep 1
		cout info "If you have the source but it's not on ~/kernel directory, you can put it on ~/kernel directory now"
		sleep 2
		haveSourceFile=false
		while [[ $haveSourceFile == "false" ]]; do
			cout info "Do you have latest kernel source (Y/n) ?"
			cin info "If you answer 'no', we will take you to download section: "
			read answerHaveSourceFile
			if [[ $answerHaveSourceFile == *[Yy]* ]] || [[ $answerHaveSourceFile == "" ]]; then
				haveSourceFile=true
				fileIsExist=true
				cout info "Please put kernel source on ~/kernel directory"
				haveCopied=false
				while [[ $haveCopied == "false" ]]; do
					cin info "Have you? (Y/n) "
					read answerHaveCopied
					if [[ $answerHaveCopied == *[Yy]* ]] || [[ $answerHaveCopied == "" ]]; then
						haveCopied=true
						haveSourceFile=true
						checkKernelSourceFile
					elif [[ $answerHaveCopied == *[Nn]* ]]; then
						cout info "Take your time"
						sleep 1
					else
						cout error "Wrong input!"
						sleep 1
					fi
				done
			elif [[ $answerHaveSourceFile == *[Nn]* ]]; then
				sleep 1
				fileIsExist=true
				haveSourceFile=true
				downloadSource
			fi
		done
	fi
	done
}

function downloadSource()
{
	cout action "Will downloading the kernel sources... This will take a several minutes, depend on your Internet Connection."
	sleep 1
	cmd="cd ~/kernel; curl -q $urlLatestKernel -o linux-$latestKernel.tar.xz"
	openTerminal > /dev/null 2>&1
	sleep 1
	cout info "Done..."
}

function extractPackage()
{
	if [[ -d ~/kernel/linux-$latestKernel ]]; then
		cout info "Source already extracted. Skipping extract to avoid replaced config file."
		sleep 1
	else
		cout action "Extracting package..."
		sleep 1
		cmd="cd ~/kernel; tar -xJvf linux-$latestKernel.tar.xz; sleep 2"
		openTerminal > /dev/null 2>&1
		cout info "Done"
		sleep 1
	fi
}

function makeXConfig()
{
	cd ~/kernel/linux-$latestKernel
	if [[ $(head -n 1 .config) == "# red-dragon" ]]; then
		cout info "Source already configured... Skipping make xconfig step..."
		sleep 1
	else
		cout action "Configuring sources..."
		sleep 1
		cout info "Note! Configuring sources is not easy! It may take a hour, or worse days. But I'll give you some tips..."
		sleep 1
		doneread=notyet
		while [[ $doneread == "notyet" ]]; do
			cout info "Take a look at 'Network device support', make sure your driver listed there, and check-listed!"
			cout info "If you need packet forwarding feature, you may to activate it. By default, it is deactivated. You can find it at 'Networking support - Network Packet Filtering Framework (Net Filter) - IP : Netfilter Configuration - IPv4 NAT - Redirect Target Support'"
			cin info "Press enter to continue"
			read answerDoneRead
			if [[ $answerDoneRead == "" ]]; then
				doneread=alldone
				cout action "Continuing to next step..."
			else
				doneread=notyet
			fi
		done
		cout info "Here we go!"
		cmd="make -j $(nproc) xconfig"
		openTerminal > /dev/null 2>&1
		if [[ $(head -n 1 .config) != "# red-dragon" ]]; then
			sed -e '1i\# red-dragon\' -i .config
		fi
		cout info "All done! So far so easy, right?"
		sleep 1
	fi
}

trap 'interrupt' INT
checkInternetConnection
checkRoot
checkLinuxType
checkDependencies
checkCurrentKernel
checkLatestKernel
getURL
setTerminal
testTerminal
createDirectory
checkKernelSourceFile
extractPackage
makeXConfig