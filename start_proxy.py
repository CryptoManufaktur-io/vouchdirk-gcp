#!/usr/bin/python3
import sys
import os
import json
import shlex
import subprocess

content = sys.stdin.read()
data = json.loads(content)

port = 8888

command = eval(f"f'{data['ssh_command']}'")

args = shlex.split(command)
subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

sys.stdout.write('{"port":"%(port)s"}\n' % {'port': port})
sys.stdout.flush()

os._exit(0)
