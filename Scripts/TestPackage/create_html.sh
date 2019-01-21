#!/bin/sh

echo "***"$*

plist_url=$1
cer_url=$2
index_html_path=$3

cat > ${index_html_path} << EOF
<html>
<style> 
body{text-align:center} 
</style> 
</head>
<meta charset="utf-8">
<body>
	<br><br>
	<br><br>
	<br><br>
	<br><br>
<a style="color:#4294ea;font-size:50px;text-decoration:none" href="itms-services://?action=download-manifest&url=${plist_url}" class="app_link">安装应用</a>
<br><br>
<br><br>
<a title="iPhone" style="color:#4294ea;font-size:50px;text-decoration:none" href="https://192.168.1.25/server.crt">安装证书192.168.1.25</a>
<br><br>
<br><br>
<p style="font-size:30px">1、安装证书。</p>
<p style="font-size:30px">2、在【设置-通用-关于本机-证书信任设置】中针对根证书启用完全信任。</p>
</body>
</html>

EOF