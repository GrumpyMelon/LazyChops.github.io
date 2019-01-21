#!/bin/bash

echo "脚本运行参数 ： ----------------------"
echo "$*"
echo "----------------------"

#参数解析。
while [ -n "$1" ]
do
    case "$1" in
    --projectPath)
		#工程目录
        project_path=$2
        shift
        ;;
    --signingType)
		#打包类型
        signingType=$2
        shift
        ;;
    --buildNumber)
        BUILD_NUMBER=$2
        shift
        ;;
     --buidCause)
        #build原因： 手动和scm触发
        BUILD_CAUSE=$2
        shift
        ;;
	--branch)
		#分支名
        branch=$2
        shift
        ;;
    --remote)
		#remote名
        remote=$2
        shift
        ;;
    --nodeName)
		#node名
        NODE_NAME=$2
        shift
        ;;
    *)
        ;;
    esac
    shift
done

echo $BUILD_CAUSE

#设置xcode build超时时间
export FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT=120

#指定输出路径
output_path="${project_path}/fastlane/build/${BUILD_NUMBER}"

#指定打包配置
export_plist_path="${project_path}/fastlane/scripts/${signingType}_ExportOptions.plist"

workspace_path="${project_path}/MojiWeather.xcworkspace"
scheme="MojiWeather"
configuration="Debug"
archive_path="${output_path}/MojiWeather.xcarchive"

ipa_name="MojiWeather_${remote}_${branch}.ipa"

#指定证书名
codesigning_identity="iPhone Developer"
if [ "$signingType"x = "AdHoc"x ]; then  
	codesigning_identity="iPhone Distribution"
fi 

mac_mini_test_node_name="mac_mini_test"
mac_mini_node_name="mac_mini"

function switchXcodeVersion() {    
	if [ "$NODE_NAME"x = "mac_mini_test"x ]; then
		#mac_mini_test上切换xcode版本。
		echo mojitest | sudo xcode-select -s "/Applications/$1"
        xcode_version=`xcodebuild -version`
        echo "Xcode版本: $xcode_version"
	fi
}

#清空旧的build
rm -rf ${project_path}/fastlane/build/*

#整理server文件夹旧的build
clean_up_script="$project_path/fastlane/scripts/TestPackage/clean_up_builds.sh"
chmod +x $clean_up_script
$clean_up_script $BUILD_NUMBER $root_password

#打包之前换成Xcode9.1
switchXcodeVersion Xcode9.1.app

#打包并导出IPA 

fastlane gym\
	--workspace ${workspace_path}\
	--configuration ${configuration}\
	--scheme ${scheme}\
	--clean true\
	--include_bitcode false\
	--include_symbols false\
	--codesigning_identity "${codesigning_identity}"\
	--output_directory ${output_path}\
	--output_name ${ipa_name}\
	--build_path ${output_path}\
	--export_options ${export_plist_path}
    
gym_result=$?
#打完包之后换回Xcode
switchXcodeVersion Xcode.app
if [ $gym_result -ne 0 ]; then
	echo "打包失败。"
	exit 1
fi

target_ipa_name="MojiWeather_${remote}_${branch}.ipa"
cd $output_path
#修改ipa名称
for file in `find . -name "*.ipa"`; do
	echo $file
	mv $file $target_ipa_name
done

server_host="https://192.168.1.25"
root_password="moji"

if [ "$NODE_NAME"x = "$mac_mini_test_node_name"x ] ; then
    server_host="https://192.168.44.66"
    root_password="mojitest"
fi

html_url="$server_host/TestPackage/$BUILD_NUMBER/index.html"
create_qrcode="$project_path/fastlane/scripts/TestPackage/create_qrcode.swift"
chmod +x $create_qrcode
#创建二维码图片。
$create_qrcode $html_url $output_path/qrcode.png

move_to_target_dir="$project_path/fastlane/scripts/TestPackage/move_to_target_dir.sh"
chmod +x $move_to_target_dir
#移动文件到指定路径
$move_to_target_dir $output_path/$target_ipa_name $server_host $root_password



    
    