#!/usr/bin/env python3

import os
import sys


def configure():
    """
    Configure the environment for the script.
    This function sets up the necessary paths and environment variables
    for the script to run correctly.
    """
    # Check if the script is being run from a specific directory
    if not os.path.exists(os.path.join(os.path.dirname(__file__), '..', 'scripts')):
        raise RuntimeError("This script must be run from the 'scripts' directory.")

    # Set up the path to the USD library based on the operating system
    current_dir = os.path.dirname(__file__)
    if os.name == 'nt':
        usd_dir = os.path.abspath(os.path.join(current_dir, '..', 'USD', 'windows', 'lib', 'python'))
        os.environ["PATH"] += f";{os.path.abspath(os.path.join(current_dir, '..', 'USD', 'windows', 'bin'))}"
        os.environ["PATH"] += f";{os.path.abspath(os.path.join(current_dir, '..', 'USD', 'windows', 'lib'))}"
        os.environ["PATH"] += f";{os.path.abspath(os.path.join(current_dir, '..', 'USD', 'windows', 'plugin', 'usd'))}"
    else:
        usd_dir = os.path.abspath(os.path.join(current_dir, '..', 'USD', 'linux', 'lib', 'python'))
        os.environ["PATH"] += f":{os.path.abspath(os.path.join(current_dir, '..', 'USD', 'linux', 'lib'))}"
        os.environ["PATH"] += f":{os.path.abspath(os.path.join(current_dir, '..', 'USD', 'linux', 'plugin', 'usd'))}"
    sys.path.insert(0, usd_dir)