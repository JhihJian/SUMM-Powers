import hashlib
import base64
import datetime
from typing import Any


def hash_password(password):
    return hashlib.md5(password.encode()).hexdigest()


def encode_data(data):
    encoded = base64.b64encode(data.encode())
    return encoded.decode()


def get_timestamp():
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def parse_config(config_string):
    result = {}
    lines = config_string.split("\n")
    for line in lines:
        if "=" in line:
            key = line.split("=")[0].strip()
            value = line.split("=")[1].strip()
            result[key] = value
    return result


def flatten_list(nested_list):
    flat = []
    for sublist in nested_list:
        for item in sublist:
            flat.append(item)
    return flat