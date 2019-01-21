#!/bin/sh

ipa_path=$1
https_host=$2
root_password=$3

server_dirname="TestPackage"
#这里写死了，不同机器不同

ipa_dir=`dirname $ipa_path`
script_dir=`dirname $0`
dir_name=`echo ${ipa_dir##*/}`
ipa_name=`echo ${ipa_path##*/}`
new_dir_path="$ipa_dir/$dir_name"

mkdir "${ipa_dir}/${dir_name}"

qrcode_image_name="qrcode.png"

cp $ipa_path "$new_dir_path/$ipa_name"
cp $ipa_dir/$qrcode_image_name "$new_dir_path/$qrcode_image_name"

ipa_url=${https_host}/${server_dirname}/${dir_name}/${ipa_name}
plist_path="$new_dir_path/$ipa_name.plist"

create_plist="$script_dir/create_plist.sh"
chmod +x $create_plist
#生成plist内容。
$create_plist $ipa_url $plist_path

index_html_path="$new_dir_path/index.html"
plist_url=${https_host}/${server_dirname}/${dir_name}/${ipa_name}.plist
#暂时写死，不同的node对应的证书不同。
cer_url="${https_host}/server.crt"

create_html="$script_dir/create_html.sh"
chmod +x $create_html
#生成html
$create_html $plist_url $cer_url $index_html_path

server_dirpath="/Library/WebServer/Documents/$server_dirname"

#删除原有的目录
echo $root_password | sudo -S rm -rf ${server_dirpath}/${dir_name}

#移动文件到根目录下。
echo $root_password | sudo -S mv $new_dir_path ${server_dirpath}/${dir_name}

