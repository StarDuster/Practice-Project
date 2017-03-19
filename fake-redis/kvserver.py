#!/usr/bin/env python3
# coding:utf-8

import selectors
import socket
import pickle
import requests

sel = selectors.DefaultSelector()
#global database
database = {}

def accept(sock, mask):
    conn, addr = sock.accept()  # Should be ready
    print('accepted', conn, 'from', addr)
    conn.setblocking(False)
    sel.register(conn, selectors.EVENT_READ, read)

def read(conn, mask):
    data_recv = conn.recv(1000)  # Should be ready
    if data_recv:
        data_send = parse_data(pickle.loads(data_recv))
        # print('echoing', pickle.loads(date_recv), 'to', conn)
        conn.send(pickle.dumps(data_send))  # Hope it won't block
    else:
        print('closing', conn)
        sel.unregister(conn)
        conn.close()

def parse_data(data):
    if data['command'] == 'set':
        database[data['key']] = data['value']
        return "done!"

    if data['command'] == 'get':
        return database[data['key']]

    if data['command'] == 'url':
        database[data['key']] = get_url(data['url'])
        print(database)
        return "done!"

def get_url(url):
    r = requests.get(url)
    try:
        value = 'length:' + r.headers['Content-Length'] + ', code: ' + str(r.status_code)
    except KeyError:
        value = 'length: None ' + ', code: ' + str(r.status_code)
    return value

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind(('localhost', 5678))
sock.listen(100)
sock.setblocking(False)
sel.register(sock, selectors.EVENT_READ, accept)

while True:
    events = sel.select()
    for key, mask in events:
        callback = key.data
        callback(key.fileobj, mask)