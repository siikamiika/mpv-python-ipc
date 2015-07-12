import sys
from subprocess import PIPE, Popen
from threading  import Thread
import time
from queue import Queue, Empty
import json
from pathlib import Path
import os
from os.path import dirname, realpath
mpv_executable = 'mpv'
if os.name == 'nt':
    mpv_executable += '.com'

script_path = Path(dirname(realpath(__file__)))

def escape(val):
    return val.replace('\\', '\\\\').replace('"', '\\"')

class MpvProcess(object):

    def __init__(self):
        self.process = Popen([mpv_executable,
            '--quiet',
            '--no-term-osd',
            '--input-terminal=no',
            '--input-file=/dev/stdin',
            '--script={}'.format(script_path / 'ipc.lua'),
            '--force-window',
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

    def slave_command(self, command):
        self.process.stdin.write((command + '\n').encode('utf-8'))
        self.process.stdin.flush()

    def get_property(self, prop, native=False):
        return self._ipc_command('getproperty{}_{}'.format(
            'native' if native else '', prop))

    def set_property(self, prop, value):
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
                sys.stdout.write(output)
            except Empty:
                break

            if output.startswith("[ipc]"):
                output = output.lstrip("[ipc]").strip()
                output = json.loads(output)
                if output[0] == self.command_id:
                    self.command_id += 1
                    return output[1] if output[1:] else None
