import sys
from subprocess import PIPE, Popen
from threading  import Thread
import time
from queue import Queue, Empty
import json
from pathlib import Path
import os
from os.path import dirname, realpath
from itertools import chain
mpv_executable = 'mpv'
if os.name == 'nt':
    mpv_executable += '.com'

script_path = Path(dirname(realpath(__file__)))

class MpvProcess(object):

    def __init__(self, debug=False):
        self.debug = debug
        self.process = Popen([mpv_executable,
            '--quiet',
            '--no-term-osd',
            '--input-terminal=no',
            '--input-file=/dev/stdin',
            '--script={}'.format(script_path / 'ipc.lua'),
            '--force-window',
            '--osc=no',
            '--idle'],
            stdout=PIPE, stdin=PIPE, bufsize=1)
        self._init_process()
        self.command_id = 0

    def _init_process(self):
        def enqueue_output(out, queue):
            for line in iter(out.readline, b''):
                queue.put(line)
            out.close()
        self.queue = Queue()
        t = Thread(target=enqueue_output, args=(self.process.stdout, self.queue))
        t.daemon = True
        t.start()

    def _escape_script_binding(self, text):
        allowed_chars = list(chain(
            range(48, 58), # 0-9
            range(65, 91), # A-Z
            range(97, 123), # a-z
        ))
        return ''.join('{{c{}}}'.format(ord(c)) if (ord(c) not in allowed_chars) else c for c in text)

    def slave_command(self, command):
        self.process.stdin.write((command + '\n').encode('utf-8'))
        self.process.stdin.flush()

    def get_property(self, prop, native=False):
        prop = self._escape_script_binding(prop)
        return self._ipc_command('getproperty{}_{}'.format(
            'native' if native else '', prop))

    def get_property_native(self, prop):
        return self.get_property(prop, True)

    def set_property(self, prop, value):
        prop = self._escape_script_binding(prop)
        value = self._escape_script_binding(json.dumps(value))
        return self._ipc_command('setproperty_{}_{}'.format(
            prop, value))

    def _ipc_command(self, command):
        self.process.stdin.write(
            'script_binding {}\n'.format(
                '{}_{}'.format(self.command_id, command)).encode('utf-8'))
        self.process.stdin.flush()
        while True:
            try:
                output = self.queue.get(True, 3).decode()
                if self.debug:
                    sys.stdout.write(output)
            except Empty:
                break

            if output.startswith("[ipc]"):
                output = output.lstrip("[ipc]").strip()
                try:
                    output = json.loads(output)
                except: continue
                if output[0] == self.command_id:
                    self.command_id += 1
                    return output[1] if output[1:] else None
