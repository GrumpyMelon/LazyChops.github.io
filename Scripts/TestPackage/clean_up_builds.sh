#!/bin/sh

current_build_number=$1
root_password=$2

max_save_number=20

server_path="/Library/WebServer/Documents/TestPackage"
dir_name_array=`ls $server_path`
for file_name in $dir_name_array; do
	#build号跟当前build号差大于20
	value=$[$current_build_number-$file_name]
	if [ $((value)) -gt $((max_save_number)) ]; then
		echo $root_password | sudo -S rm -rf $server_path/$file_name
	fi
done