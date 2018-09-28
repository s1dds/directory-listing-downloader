#!/bin/bash

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.


export RED='\033[1;31m'
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[1;34m'
export MAGENTA='\033[1;35m'
export CYAN='\033[1;36m'
export WHITE='\033[1;37m'
export RESETCOLOR='\033[1;00m'

declare -a dir_pending
header="Accept: text/html"
user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0"

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

function init() {
	echo -ne "$CYAN Enter URL to download: $WHITE"
	read root
	echo -ne "$CYAN Enter folder name to save data in: $WHITE"
	read folder
	root_dir=$(pwd)'/'$folder
	dir_exist_check $root_dir
	if [ "$dir_exist" = false ]; then
		mkdir $root_dir && cd $root_dir
	else
		cd $root_dir
	fi
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
	if [ $len -lt 24 ]; then
		tabs='\t\t\t\t\t\t'
	elif [ $len -gt 23 ] && [ $len -lt 31 ] ; then
		tabs='\t\t\t\t\t'
	elif [ $len -gt 30 ] && [ $len -lt 39 ]; then
		tabs='\t\t\t\t'
	elif [ $len -gt 38 ] && [ $len -lt 47 ]; then
		tabs='\t\t\t'
	elif [ $len -gt 46 ] && [ $len -lt 55 ]; then
		tabs='\t\t'
	elif [ $len -gt 54 ] && [ $len -lt 62 ]; then
		tabs='\t'
	else
		tabs=''
	fi
}

function dir_exist_check() {
	if [ -d "$1" ]; then
		dir_exist=true
	else
		dir_exist=false
	fi
}

function file_exist_check() {
	if [ -e "$1" ]; then
		file_exist=true
	else
		file_exist=false
	fi
}

function display_ok() {
	if [ -e "$1" ]; then
		echo -e "$BLUE [ $GREEN OK $BLUE ] $RESETCOLOR"
	else
		echo -e "$BLUE [$RED Failed $BLUE] $RESETCOLOR"
	fi
}

main() {
	echo
	url=$root$1
	spaces "Getting info: $url"
	echo -e -n "$WHITE Getting info: $MAGENTA$url$tabs  "
	file_exist_check "index.html"
	if [ "$file_exist" = false ]; then
		wget -q --header=$header --user-agent=$user_agent $url &
		spinner
	fi
	display_ok "index.html"
	list=($(grep "href=" index.html | cut -d '"' -f 2))
	for i in "${list[@]}"; do
		if [ $i != '../' ] && [[ $i != '/'* ]] && [[ $i != 'href='* ]] && [[ $i != 'http'* ]] && [[ $i != *'<'* ]] && [[ $i != '<'* ]]; then
			if [[ $i == */ ]]; then
				dir_name=$(echo -n "$i" | sed -r 's/%20/ /g')
				echo -e "$BLUE Directory found $YELLOW$dir_name$RESETCOLOR"
				dir_pending+=($1$i)
				dir_exist_check "$dir_name"
				if [ "$dir_exist" = false ]; then
					mkdir "$dir_name"
				fi
			elif [[ $i == *.* ]]; then
				f_name=$(echo -n "$i" | sed -r 's/%20/ /g')
				file_exist_check "$f_name"
				if [ "$file_exist" = false ]; then
					file_exist_check "$f_name.incomplete"
					if [ "$file_exist" = true ]; then
						spaces "Resuming $f_name"
						echo -e -n "$RED Resuming $CYAN$f_name$RESERCOLOR$tabs  "
						wget -q -c --header=$header --user-agent=$user_agent $url$i -O "$f_name.incomplete" &
					else
						spaces "Downloading $f_name"
						echo -e -n "$BLUE Downloading $CYAN$f_name$RESERCOLOR$tabs  "
						wget -q --header=$header --user-agent=$user_agent $url$i -O "$f_name.incomplete" &
					fi
					spinner
					mv "$f_name.incomplete" "$f_name" 2>/dev/null
				else
					spaces "Completed $f_name"
					echo -e -n "$MAGENTA Completed $CYAN$f_name$RESERCOLOR$tabs  "
				fi
				display_ok "$f_name"
			fi
		fi
	done
}

function cleanup() {
	cleanup_files=($(find "$root_dir" -name "index.html"))
	for file in ${cleanup_files[@]}; do
		rm "$file"
	done
}

clear
banner
init
if [[ $root == */ ]]; then
	main
else
	main '/'
fi
index=0
while [ ${#dir_pending[@]} -gt 0 ]; do
	d=${dir_pending[$index]}
	cd $root_dir'/'$d
	main $d
	unset dir_pending[$index]
	((index++))
done
cleanup
echo -e "$GREEN\n Download Complete!!$RESETCOLOR"
