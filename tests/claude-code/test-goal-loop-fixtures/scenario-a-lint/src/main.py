import os
import sys
import json
import unused_module
from typing import List, Dict, Optional


def calculate_sum(data):
    result = 0
    for i in range(len(data)):
        result = result + data[i]
    return result


def process_user(name, age, email, phone, address, city, country, zipcode):
    user_info = {}
    user_info["name"] = name
    user_info["age"] = age
    user_info["email"] = email
    user_info["phone"] = phone
    user_info["address"] = address
    user_info["city"] = city
    user_info["country"] = country
    user_info["zipcode"] = zipcode
    return user_info


def get_config_value(config_dict, key, default_value=None):
    if config_dict != None:
        if key in config_dict:
            return config_dict[key]
    return default_value


class UserManager:
    def __init__(self):
        self.users = []

    def add_user(self, user):
        self.users.append(user)

    def remove_user(self, user):
        if user in self.users:
            self.users.remove(user)

    def find_user(self, name):
        for user in self.users:
            if user["name"] == name:
                return user
        return None

    def get_all_names(self):
        names = []
        for user in self.users:
            names.append(user["name"])
        return names


def format_output(data, pretty=False, indent=2, sort_keys=False):
    if pretty == True:
        return json.dumps(data, indent=indent, sort_keys=sort_keys)
    return json.dumps(data)


def validate_email(email):
    if "@" in email:
        if "." in email.split("@")[1]:
            return True
    return False