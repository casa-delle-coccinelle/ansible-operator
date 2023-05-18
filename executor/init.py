#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2023 nelly <nelly@vivobook>
#
# Distributed under terms of the MIT license.

"""

"""

import os
from jinja2 import Environment, FileSystemLoader
from git import Repo
from git import Git
from git import RemoteProgress
import argparse
from ruamel.yaml import YAML
import logging
import sys

logger = logging.getLogger("ansible-executor")
logging.basicConfig(stream=sys.stdout,
                    format='%(asctime)s [%(levelname)s] - %(name)s - %(message)s',
                    datefmt='%m/%d/%Y %I:%M:%S %p')
logger.setLevel(logging.INFO)


def parse_args():
    """ Parse command line arguments. """

    parser = argparse.ArgumentParser(prog="zeus", description='Outdoor lights automation')
    parser.add_argument("-c", "--config_file", help="Configuration files path", action='append')

    args = parser.parse_args()
    return args


def getConfiguration(config_files=None):
    yaml = YAML()
    config = {}

    if config_files is not None:
        logger.info(f"Script started with configuration files {config_files}")
        for file in config_files:
            logger.info(f'Loading configuration file {file}')
            with open(file) as f:
                config_data = yaml.load(f)
                for key, value in config_data.items():
                    if key not in config:
                        config.update({key: config_data[key]})
                        logger.info(f'Updating configuration for key {key} from file {file}')
                    elif key in config and value != config[key]:
                        config.update({key: config_data[key]})
                        logger.info(f'Updating configuration for key {key} from file {file}')
        return config

    logger.info('No configuration was provided')
    return config


def ssh_config(keys_path='/home/ansible/keys'):

    # print(os.path.expanduser)

    keys_dirs = []
    ssh_config_list = []
    ssh_config_path = []

    if os.path.exists(keys_path) and os.path.isdir(keys_path):
        keys_dirs = [os.path.join(keys_path, key) for key in os.listdir(keys_path)]
        print(keys_dirs)
        for key in keys_dirs:
            print(f'>>>>> {key}')
            if 'ssh-privatekey' in os.listdir(key):
                print(os.path.join(key, 'ssh-privatekey'))
                identity_key_path = os.path.join(key, 'ssh-privatekey')
            if 'config' in os.listdir(key):
                for config in os.listdir(os.path.join(key, 'config')):
                    ssh_config_path.append(os.path.join(key, 'config', config))
            if 'secret-config' in os.listdir(key):
                for secret_config in os.listdir(os.path.join(key, 'secret-config')):
                    print(f'>>>>>>>>>>>> {secret_config}')
                    ssh_config_path.append(os.path.join(key, 'secret-config', secret_config))
            ssh_config_list.append({'identity_key': identity_key_path, 'config_path': ssh_config_path.copy()})
            ssh_config_path.clear()

    print(ssh_config_list)

    environment = Environment(loader=FileSystemLoader("./"), trim_blocks=True, lstrip_blocks=True)
    template = environment.get_template('ssh_config.j2')
    environment.globals['include_file'] = include_file
    content = template.render(keys=ssh_config_list)
    print(content)


def include_file(name):
    with open(name) as f:
        content = f.read()
        content = content.rstrip('\n')
        return content


def clone_git_repo(config, repo_dest):
    _repo = config.get('git_repo')
    _repo_branch = config.get('git_repo_branch')
    _username = config.get('git_username')
    _password = config.get('git_password')
    _token = config.get('git_token')

    repo_url = f'ssh://{_repo}'

# TODO GitPython lib prints the cmd on fail (username and password are visible)
    if _token is not None:
        repo_url = f'https://{_token}@{_repo}'
    elif _username is not None and _password is not None:
        repo_url = f'https://{_username}:{_password}@{_repo}'
    Repo.clone_from(repo_url, repo_dest, branch=_repo_branch, depth=1)


def main():
    config_files = vars(parse_args())
    config_files_list = config_files['config_file']
    config = getConfiguration(config_files_list)
    print(config)

    ssh_config(keys_path='/tmp/python_test')

    # clone_git_repo(config, '/tmp/python_repo_test/repo')


if __name__ == '__main__':
    main()
