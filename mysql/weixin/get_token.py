# coding=utf-8
import requests

import logging_01


def get_token_in_time(corp_id='wx512775916d2936ff', secret='nWf3k0nMZkCy1X0ry3bJGUF-XOgE6U2Hv0X0cVHxKOscy6K1f8yvphUK_KZAmxdR'):
    res = requests.get('https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=%s&corpsecret=%s' % (corp_id, secret))
    res = res.json()
    token = res.get('access_token', False)
    #logging_01.log_jilu(info=token)
    return token


def get_auth_code(code):
    rest = requests.get('https://qyapi.weixin.qq.com/cgi-bin/user/getuserinfo?access_token=%s&code=%s' %
                        (get_token_in_time(),code))
    return rest.content

#https://qyapi.weixin.qq.com/cgi-bin/user/getuserinfo?access_token=ACCESS_TOKEN&code=CODE


if __name__ == '__main__':

    #
    corp_id = 'wx512775916d2936ff'
    Secret = 'nWf3k0nMZkCy1X0ry3bJGUF-XOgE6U2Hv0X0cVHxKOscy6K1f8yvphUK_KZAmxdR'

    print get_token_in_time()


