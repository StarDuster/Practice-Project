#!/usr/bin/env python3
# coding:utf-8

import socket
import argparse
import pickle
from cmd import Cmd


class KvClient(Cmd):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    data_dict = {}
    cookie = ""

    def __init__(self, HOST, PORT):
        Cmd.__init__(self)
        self.prompt = '(kvclient) '
        self.intro = "Welcome to fake-redis, a useless kv storage service"
        server_address = (str(HOST), int(PORT))
        print('connecting to {} port {}'.format(*server_address))
        try:
            self.sock.connect(server_address)
        except ConnectionError as error:
            print(error, "\r\nSocket connect failed, is the server running?")
            exit(1)

    def do_set(self, line):
        args = str(line).split()
        self.data_dict['command'] = 'set'
        try:
            self.data_dict['key'] = str(args[0])
            self.data_dict['value'] = str(args[1])
        except IndexError:
            print("input is invalid")
            return
        self.send_data(self.data_dict)

    def do_get(self, line):
        args = str(line).split()
        self.data_dict['command'] = 'get'
        try:
            self.data_dict['key'] = str(args[0])
        except IndexError:
            print("input is invalid")
            return
        self.send_data(self.data_dict)

    def do_auth(self, line):
        args = str(line).split()
        self.data_dict['command'] = 'auth'
        try:
            self.data_dict['username'] = str(args[0])
            self.data_dict['password'] = str(args[1])
        except IndexError:
            print("input invalid")
            return
        self.send_data(self.data_dict)

    def do_url(self, line):
        args = str(line).split()
        self.data_dict['command'] = 'url'
        try:
            self.data_dict['key'] = str(args[0])
            self.data_dict['url'] = str(args[1])
        except IndexError:
            print("input invalid")
            return
        self.send_data(self.data_dict)

    def send_data(self, data):
        self.data_dict['cookie'] = self.cookie
        message = pickle.dumps(data)
        self.sock.sendall(message)
        recv_data = self.sock.recv(1024)
        print('Received', pickle.loads(recv_data))
        try:
            if pickle.loads(recv_data)['cookie'] is not None:
                self.cookie = pickle.loads(recv_data)['cookie']
        except (KeyError, TypeError):
            pass

    def postcmd(self, stop, line):
        self.lastcmd = ''

def parse_args():
    parser = argparse.ArgumentParser(description='set bind address')
    parser.add_argument('--port', dest='port', default=5678,
                        help='server port to connect')
    parser.add_argument('--host', dest='host', default='127.0.0.1',
                        help='the server ip')
    return parser.parse_args()


def main():
    args = parse_args()
    client = KvClient(args.host, args.port)
    client.cmdloop()


if __name__ == '__main__':
    main()
