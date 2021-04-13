# mpv-python-ipc

A cross-platform alternative to JSON IPC.

Uses a hack with the lua event `client-message`. Sending `script_binding some_command` to stdin with `input-file=/dev/stdin` triggers a `client-message`, that gets `some_command` in arguments. That's where we put stuff like `get_property`.

## Usage

```python
from mpv_python_ipc import MpvProcess


mp = MpvProcess()
print(mp.get_property("idle"))
```

## Note

~Named pipe IPC support has been added to mpv master. This project will probably eventually switch to using it and JSON IPC instead of the ugly hack it currently uses.~

Update: --input-file=/dev/stdin support was removed from mpv. Use [Python MPV JSONIPC](https://github.com/iwalton3/python-mpv-jsonipc) instead.

How to port existing code:
https://github.com/siikamiika/scripts/commit/4809a5a9b85b2e2a1cea1f0680c4a793d3b655a2
