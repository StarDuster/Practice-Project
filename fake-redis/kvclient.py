#!/usr/bin/env python3
# coding:utf-8

import sys
import socket
import argparse
import pickle
from cmd2 import Cmd


class KvClient(Cmd):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    data_dic = {}
    #full format {'command':'', 'key':'', 'value':'', 'url':'','username':'', 'password':'', 'cookie':''}
    cookie = ""

    def __init__(self):
        """Constructor"""
        Cmd.__init__(self)
        self.prompt = '(kvclient) '
        self.intro = "Welcome to fake-redis, a useless kv storage service"
        server_address = (str(HOST), int(PORT))
        print('connecting to {} port {}'.format(*server_address))
        try:
            self.sock.connect(server_address)
        except Exception as e:
            print(e, "\r\nSocket connect failed, exit")
            exit(1)

    def do_set(self, line):
        args = str(line).split()
        self.data_dic['command'] = 'set'
        self.data_dic['key'] = str(args[0])
        self.data_dic['value'] = str(args[1])
        self.send_data(self.data_dic)

    def do_get(self, line):
        args = str(line).split()
        self.data_dic['command'] = 'get'
        self.data_dic['key'] = str(args[0])
        self.send_data(self.data_dic)

    def do_auth(self, line):
        args = str(line).split()
        self.data_dic['command'] = 'auth'
        self.data_dic['username'] = str(args[0])
        self.data_dic['password'] = str(args[1])
        self.send_data(self.data_dic)

    def do_url(self, line):
        args = str(line).split()
        self.data_dic['command'] = 'url'
        self.data_dic['key'] = str(args[0])
        self.data_dic['url'] = str(args[1])
        self.send_data(self.data_dic)

    def send_data(self, data):
        self.data_dic['cookie'] = self.cookie
        message = pickle.dumps(data)
        #DEBUG print('sending {!r}'.format(message))
        self.sock.sendall(message)
        recv_data = self.sock.recv(1024)
        print('Received', pickle.loads(recv_data))
        try:
            if pickle.loads(recv_data)['cookie'] is not None:
                self.cookie = pickle.loads(recv_data)['cookie']
        except KeyError and TypeError:
            pass

def parse_args():
    parser = argparse.ArgumentParser(description='set bind address')
    parser.add_argument('--port', dest='port',
                        help='server port to connect')
    parser.add_argument('--host', dest='host',
                        help='the server ip')

    args = parser.parse_args()
    # DEBUG: print(args.host, args.port)
    sys.argv = sys.argv[0:0]
    return (args.host, args.port)


def main():
    params = parse_args()
    global HOST, PORT
    HOST = params[0]
    PORT = params[1]
    if (HOST is None or PORT is None):
        HOST = '127.0.0.1'
        PORT = 5678

    client = KvClient()
    client.cmdloop()


if __name__ == '__main__':
    main()
