#!/usr/bin/env python3

from distutils.core import setup

setup(name='mpv_python_ipc',
    version='1.0',
    description='Python bindings to mpv lua api',
    author='siikamiika',
    url='https://github.com/siikamiika/mpv-python-ipc',
    packages=['mpv_python_ipc'],
    package_data={'mpv_python_ipc': ['ipc.lua']},
)
