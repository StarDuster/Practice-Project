#!/usr/bin/env python3
# coding:utf-8

import selectors
import socket
import pickle
import argparse
import hashlib
import time
import requests

sel = selectors.DefaultSelector()
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
database_dict = {}
password_dict = {}
cookie_list = []


def accept(sock, mask):
    conn, addr = sock.accept()
    print('accepted', conn, 'from', addr)
    conn.setblocking(False)
    sel.register(conn, selectors.EVENT_READ, read)


def read(conn, mask):
    data_recv = conn.recv(1000)
    if data_recv:
        data_send = parse_data(pickle.loads(data_recv))
        conn.send(pickle.dumps(data_send))
    else:
        print('closing', conn)
        sel.unregister(conn)
        conn.close()


def parse_data(data):
    if data['command'] == 'set':
        database_dict[data['key']] = data['value']
        return "done!"

    if data['command'] == 'get':
        return database_dict[data['key']]

    if data['command'] == 'auth':
        return do_auth(data)

    if data['command'] == 'url':
        if data['cookie'] not in cookie_list:
            return "not authed"
        url_result = get_url(data['url'])
        if url_result is not None:
            database_dict[data['key']] = url_result
            return "done!"
        else:
            return "url get fail!"


def get_url(url):
    try:
        r = requests.get(url, timeout=1)
    except:
        return None
    try:
        value = 'length:' + r.headers['Content-Length'] \
                + ', code: ' + str(r.status_code)
    except KeyError:
        value = 'length: None ' + ', code: ' + str(r.status_code)
    return value


def do_auth(data):
    username = data['username']
    password = data['password']
    if username in password_dict and password_dict[username] == password:
        m = hashlib.md5()
        m.update((str(time.time()) + username).encode('utf-8'))
        cookie = m.hexdigest()[:8]
        cookie_list.append(cookie)
        return {'cookie':cookie}
    else:
        return "auth fail"


def parse_args():
    parser = argparse.ArgumentParser(description='set bind address')
    parser.add_argument('--port', dest='port', default=5678,
                        help='server port to connect')
    parser.add_argument('--host', dest='host', default='127.0.0.1',
                        help='the server ip')
    return parser.parse_args()


def main():
    with open('./auth.conf', 'r') as config_file:
        for line in config_file.readlines():
            username, password = line.strip('\n').split(':')
            password_dict[username] = password

    args = parse_args()
    server_address = (str(args.host), int(args.port))
    sock.bind(server_address)
    sock.listen(100)
    sock.setblocking(False)
    sel.register(sock, selectors.EVENT_READ, accept)
    print('server starting up on {} port {}'.format(*server_address))

    while True:
        events = sel.select()
        for key, mask in events:
            callback = key.data
            callback(key.fileobj, mask)

if __name__ == '__main__':
    main()