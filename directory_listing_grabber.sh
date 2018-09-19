#!/bin/bash

export RED='\033[1;31m'
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[1;34m'
export MAGENTA='\033[1;35m'
export CYAN='\033[1;36m'
export WHITE='\033[1;37m'
export RESETCOLOR='\033[1;00m'

declare -a dir_pending

function banner() {
	echo -ne "$YELLOW"
	printf "
		    _                   __                
		   | \o.__  __|_ _ ._  /__.__.|_ |_  _ ._ 
		   |_/||(/_(_ |_(_)|\/ \_||(_||_)|_)(/_|  
		                    /                     "
	echo	
	echo -e "$RESETCOLOR"
}

function input() {
	echo -ne "$CYAN Enter URL to download: $WHITE"
	read root
	echo -ne "$CYAN Enter folder name to save data in: $WHITE"
	read folder
	init
}

function init() {
	root_dir=$(pwd)'/'$folder
	mkdir $root_dir && cd $root_dir
}

function spinner() {
	sp=('.   ' '..  ' '... ' '....' ' ...' '  ..' '   .' '  ..' ' ...' '....' '... ' '..  ' '.   ')
	pid=$!
	while kill -0 $pid 2> /dev/null;
	do	
		x=0
		for ch in ${sp[@]}
		do
			echo -n -e "$BLUE [$GREEN ${sp[$x]} $BLUE]"
			echo -n -e "\b\b\b\b\b\b\b\b\b"
			sleep 0.1
			((x++))
		done
	done
}

function spaces() {
	name=$1
	len=${#name}
	if [ $len -lt 19 ]; then
		tabs='\t\t\t\t\t'
	elif [ $len -gt 18 ] && [ $len -lt 26 ]; then
		tabs='\t\t\t\t'
	elif [ $len -gt 25 ] && [ $len -lt 33 ]; then
		tabs='\t\t\t'
	elif [ $len -gt 32 ] && [ $len -lt 38 ]; then
		tabs='\t\t'
	elif [ $len -gt 37 ] && [ $len -lt 40 ]; then
		tabs='\t'	
	else
		tabs=''
	fi
}

function download_dir() {
	echo
	spaces $1
	echo -e -n "$WHITE Getting info: $MAGENTA$1$tabs  "
	wget -q $1'/' &
	spinner
	if [ -e 'index.html' ]
	then
		echo -e "$BLUE [ $GREEN OK $BLUE ] $RESETCOLOR"
	else
		echo -e "$BLUE [$RED Failed $BLUE] $RESETCOLOR"
	fi
}

main() {
	download_dir $root$1
	list=($(grep "href=" index.html | cut -d '"' -f 2))

	for i in "${list[@]}"
	do
		if [ $i != '../' ]
		then
			if [[ $i == */ ]]
			then
				echo -e "$BLUE Directory found $YELLOW$i$RESETCOLOR"
				dir_pending+=($1$i)
				mkdir $i
			else
				spaces $i
				echo -e -n "\b$BLUE Downloading $CYAN$i$RESERCOLOR$tabs  "
				wget -q $root$1$i &
				spinner
				if [ -e $i ]
				then
					echo -e "$BLUE [ $GREEN OK $BLUE ] $RESETCOLOR"
				else
					echo -e "$BLUE [$RED Failed $BLUE] $RESETCOLOR"
				fi
			fi
		fi
	done
	rm index.html
}

clear
banner
input
if [[ $root == */ ]]; then
	main
else
	main '/'
fi
index=0
while [ ${#dir_pending[@]} -gt 0 ]
do
	d=${dir_pending[$index]}
	cd $root_dir$d
	main $d
	unset dir_pending[$index]
	((index++))
done

