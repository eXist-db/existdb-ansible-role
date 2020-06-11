#!/usr/bin/python3
# -*- coding: utf-8 -*-

import argparse
import base64
import os
import socket
import sys

from xmlrpc.client import ServerProxy, Error

parser = argparse.ArgumentParser()
#parser.add_argument("echo", help="echo the string you use here", type=str)
#parser.add_argument("num", type=int, help="double the number you use here")
parser.add_argument("-d", "--debug",  action="store_true", help="enable debug output")
parser.add_argument("-t", "--timeout", type=int, default=180, help="connection timeout")
parser.add_argument("-u", "--user", default="admin", help="username to login to eXist XML RPC (default: admin)")
parser.add_argument("-p", "--pass", default="", help="password to login to eXist XML RPC (default: \"\")")
parser.add_argument("-H", "--host", default="localhost", help="URL hostname (default: localhost)")
parser.add_argument("-P", "--port", type=int, default=8080, help="URL port (default: 8443)")
parser.add_argument("-T", action="store_true", help="disable TLS connection (default: enabled)")
parser.add_argument("-o", "--owner", default="admin", help="set owner of uploaded file (default: admin)")
parser.add_argument("-g", "--group", default="SYSTEM", help="set group of uploaded file (default: SYSTEM)")
parser.add_argument("-m", "--mode", default="rw-r--r--", help="set mode  of uploaded file (default: rw-r--r--) - NOT 0644 format!")
parser.add_argument("-M", "--mime", default="application/xml", help="set MIME type of uploaded file (default: application/xml)")
parser.add_argument("-Q", action="store_true", help="uploaded file is XQuery, shortcut for \"-M application/xquery\"")
parser.add_argument("-L", action="store_true", help="uploaded file is HTML, shortcut for \"-M text/html\"")
parser.add_argument("-B", action="store_true", help="uploaded file is binary [NOT IMPLEMENTED YET]")
parser.add_argument("file-name", default="", nargs="?", help="name of file to upload")
args = parser.parse_args()
#print(args)

xmlrpcDebug = args.debug
xmlrpcTimeout = args.timeout
xmlrpcUser = args.user
xmlrpcPass = vars(args)['pass']
xmlrpcHost = args.host
xmlrpcPort = args.port
xmlrpcSchema = "https"
if args.T:
    xmlrpcSchema = "http"
xmlrpcOwner = args.owner
xmlrpcMode = args.mode
xmlrpcMime = args.mime
if args.Q:
    xmlrpcMime = "application/xquery"
if args.L:
    xmlrpcMime = "text/html"
if args.B:
    xmlrpcMime = "application/octet-stream"

scriptName = os.path.basename(sys.argv[0])
#print(scriptName)
fname = sys.argv[-1]
#print(fname)

data = sys.stdin.read().encode()
#data = "\n".join(sys.stdin.readlines())
#print(data)
#sys.exit()



socket.setdefaulttimeout(xmlrpcTimeout)

with ServerProxy('{xmlrpcSchema}://{xmlrpcUser}:{xmlrpcPass}@{xmlrpcHost}:{xmlrpcPort}/exist/xmlrpc'.format(**locals())) as proxy:
    #print(proxy)
    if (scriptName == 'execute-xmlrpc.py'):
        print(scriptName)
        #xquery = '(<test1/>,<test2/>)'
        xquery = data
        limitResultNumberTo = 100 # 0 to disable
        startWithResultNumber = 1
        params = {}
        try:
            print(proxy.query(xquery, limitResultNumberTo, startWithResultNumber, params))
        except Error as v:
            print("ERROR", v)
            sys.exit(-1)
        pass
        sys.exit()
    elif (scriptName == 'upload-xmlrpc.py'):
        #print(scriptName)
        #b64 = base64.b64encode(data.encode('utf-8'))
        upres = -1
        pares = -1
        spres = -1
        try:
            #upres = proxy.upload(data, len(base64(data)))
            upres = proxy.upload(data, len(data))
            print(upres)
            #pares = proxy.parseLocalExt(str(upres), fname, replace=1, mime='application/xml', parse=1)
            pares = proxy.parseLocalExt(str(upres), fname, 1, xmlrpcMime, 1)
            print(pares)
            #spres = proxy.setPermissions(fname, owner='admin', group='SYSTEM', mode='rw-r--r--')
            spres = proxy.setPermissions(fname, 'admin', 'SYSTEM', 'rw-r--r--')
            print(spres)
        except Error as v:
            print("ERROR", v)
            sys.exit(-1)
        pass
        sys.exit()

if __name__=='__main__':
    #print("hello, world!")
    pass
