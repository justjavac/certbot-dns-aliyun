#!/bin/bash
FLAG=".com.cn|.gov.cn|.net.cn|.org.cn|.ac.cn|.gd.cn"  


if ! command -v aliyun >/dev/null; then
	echo "错误: 你需要先安装 aliyun 命令行工具 https://help.aliyun.com/document_detail/121541.html。" 1>&2
	exit 1
fi

DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')
SUB_DOMAIN=$(expr match "$CERTBOT_DOMAIN" '\(.*\)\..*\..*')

if echo $CERTBOT_DOMAIN |grep -E -q "$FLAG"; then

  DOMAIN=`echo $CERTBOT_DOMAIN |grep -oP '(?<=)[^.]+('$FLAG')'`
  SUB_DOMAIN=`echo $CERTBOT_DOMAIN |grep -oP '.*(?=\.[^.]+('$FLAG'))'`

fi

if [ -z $DOMAIN ]; then
    DOMAIN=$CERTBOT_DOMAIN
fi
if [ ! -z $SUB_DOMAIN ]; then
    SUB_DOMAIN=.$SUB_DOMAIN
fi

if [ $# -eq 0 ]; then
	aliyun alidns AddDomainRecord \
		--DomainName $DOMAIN \
		--RR "_acme-challenge"$SUB_DOMAIN \
		--Type "TXT" \
		--Value $CERTBOT_VALIDATION
	/bin/sleep 20
else
	RecordId=$(aliyun alidns DescribeDomainRecords \
		--DomainName $DOMAIN \
		--RRKeyWord "_acme-challenge"$SUB_DOMAIN \
		--Type "TXT" \
		--ValueKeyWord $CERTBOT_VALIDATION \
		| grep "RecordId" \
		| grep -Eo "[0-9]+")

	aliyun alidns DeleteDomainRecord \
		--RecordId $RecordId
fi
