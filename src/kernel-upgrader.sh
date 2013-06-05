#!/bin/bash

# Variable
currentKernel=$(uname -r)
latestKernel=$(curl https://www.kernel.org/ -s | sed -n "/<td id=\"latest_link\">/,/<\/td>/p" | sed -n -e 's/.*<a.*>\(.*\)<\/a>.*/\1/p');
urlLatestKernel=$(echo "https://www.kernel.org$(curl https://www.kernel.org/ -s | grep $latestKernel | grep downloadarrow | awk -F "<" {'print $2'} | sed "s/a href\=\".\|\">//g")")
totalProcessor=$(nproc)
linuxType=$(lsb_release --short --id)

# Function
cin() {
	if [ "$1" == "action" ] ; then output="\e[01;32m[>]\e[00m" ; fi
	if [ "$1" == "info" ] ; then output="\e[01;33m[i]\e[00m" ; fi
	if [ "$1" == "error" ] ; then output="\e[01;31m[!]\e[00m" ; fi
	output="$output $2"
	echo -en "$output"
}
 
cout() {
	if [ "$1" == "action" ] ; then output="\e[01;32m[>]\e[00m" ; fi
	if [ "$1" == "info" ] ; then output="\e[01;33m[i]\e[00m" ; fi
	if [ "$1" == "error" ] ; then output="\e[01;31m[!]\e[00m" ; fi
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
			cout error "build-essential is not installed yet. Please install it before using this script."
			cout action "Quiting..."
			sleep 1
			exit 1
		else
			cout info "Found build-essential."
		fi
		cout action "Checking fakeroot..."
		sleep 1
		if [[ $(dpkg -l | grep ii | grep fakeroot | awk {'print $2'}) == "" ]]; then
			cout error "fakeroot is not installed yet. Please install it before using this script."
			cout action "Quiting..."
			sleep 1
			exit 1
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
	cmd="whoami; sleep 3"
	openTerminal 2&>1 /dev/null
	if [[ $? -eq 0 ]]; then
		cout info "Looks good..."
		sleep 1
	else
		cout error "Looks not good... It's OK tho, but you may experience some problems on installation..."
	fi
}

trap 'interrupt' INT
checkRoot
checkLinuxType
checkDependencies
checkCurrentKernel
checkLatestKernel
getURL
setTerminal
testTerminal