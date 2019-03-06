#!/usr/bin/python
#coding=utf-8
import requests
import get_token
import sys
args = sys.argv[1:][0]
wxzh = sys.argv[-1]
data=""" {"touser":"%s","msgtype":"text","agentid":1,"text":{"content":"%s"}}""" % (wxzh,args)
ACCESS_TOKEN = get_token.get_token_in_time()
r = requests.post(url="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s" % ACCESS_TOKEN,data=data)
print r.text
