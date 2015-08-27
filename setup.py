#!/usr/bin/env python3

from distutils.core import setup

setup(name='mpv-python-ipc',
    version='1.0',
    description='Python bindings to mpv lua api',
    author='siikamiika',
    url='https://github.com/siikamiika/mpv-python-ipc',
    packages=['mpv-python-ipc'],
    package_data={'mpv-python-ipc': ['ipc.lua']},
    package_dir={'mpv-python-ipc': '.'}
)
