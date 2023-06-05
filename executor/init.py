#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2023 nelly <nelly@vivobook>
#
# Distributed under terms of the MIT license.

# noqa: E501

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
import subprocess

logger = logging.getLogger("ansible-executor")
logging.basicConfig(stream=sys.stdout,
                    format='%(asctime)s [%(levelname)s] - %(name)s - %(message)s',
                    datefmt='%m/%d/%Y %I:%M:%S %p')
logger.setLevel(logging.INFO)


def parse_args():
    """ Parse command line arguments. """

    parser = argparse.ArgumentParser(prog="ansible-executor", description='Run ansible playbook')
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


def load_ssh_config(keys_path='/home/ansible/keys'):

    # print(os.path.expanduser)

    keys_dirs = []
    ssh_config_list = []
    ssh_config_path = []

    if os.path.exists(keys_path) and os.path.isdir(keys_path):
        keys_dirs = [os.path.join(keys_path, key) for key in os.listdir(keys_path)]
        for key in keys_dirs:
            if 'ssh-privatekey' in os.listdir(key):
                identity_key_path = os.path.join(key, 'ssh-privatekey')
            if 'config' in os.listdir(key):
                for config in os.listdir(os.path.join(key, 'config')):
                    if os.path.isfile(os.path.join(key, 'config', config)):
                        ssh_config_path.append(os.path.join(key, 'config', config))
            if 'secret-config' in os.listdir(key):
                for secret_config in os.listdir(os.path.join(key, 'secret-config')):
                    if os.path.isfile(os.path.join(key, 'secret-config', secret_config)):
                        ssh_config_path.append(os.path.join(key, 'secret-config', secret_config))
            ssh_config_list.append({'identity_key': identity_key_path, 'config_path': ssh_config_path.copy()})
            ssh_config_path.clear()

    generate_ssh_config(ssh_config_list)



def generate_ssh_config(ssh_config):

    user_home = os.environ.get('HOME')

    if not os.path.exists(os.path.join(user_home, '.ssh')):
        os.makedirs(os.path.join(user_home, '.ssh'))
        os.chmod(os.path.join(user_home, '.ssh'), 0o600)

    environment = Environment(loader=FileSystemLoader("./"), trim_blocks=True, lstrip_blocks=True)
    template = environment.get_template('ssh_config.j2')
    environment.globals['include_file'] = include_file
    content = template.render(keys=ssh_config)

    with open(os.path.join(user_home, '.ssh', 'config'), 'w') as f:
        f.write(content)


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

    repo_url = f'{_repo}'

# TODO GitPython lib prints the cmd on fail (username and password are visible)
# TODO add url encoding
    if _token is not None:
        repo_url = f'https://{_token}@{_repo}'
    elif _username is not None and _password is not None:
        repo_url = f'https://{_username}:{_password}@{_repo}'
    Repo.clone_from(repo_url, repo_dest, branch=_repo_branch, depth=1)


def install_galaxy_requirements(path):
    # TODO: Add retry

    logger.info(f'Installing ansible galaxy requirements from file {path}')
    galaxy = subprocess.run(["ansible-galaxy", "install", "-r", path], capture_output=True)
    logger.info(f'Ansible galaxy execution output was: "{galaxy.stdout}"')
    logger.info(f'Ansible galaxy installation exit code is {galaxy.returncode}')


def load_playbook_inventory(path):

    inventory = []

    if os.path.exists(path) and os.path.isdir(path):
        if "secret-inventory" in os.listdir(path):
            for inventory_file in os.listdir(os.path.join(path, "secret-inventory")):
                if os.path.isfile(os.path.join(path, 'secret-inventory', inventory_file)):
                    #inventory = " -i ".join([inventory, os.path.join(path, "secret-inventory", inventory_file)])
                    inventory.append('-i')
                    inventory.append(os.path.join(path, "secret-inventory", inventory_file))
        if "inventory" in os.listdir(path):
            for inventory_file in os.listdir(os.path.join(path, "inventory")):
                if os.path.isfile(os.path.join(path, 'inventory', inventory_file)):
                    #inventory = " -i ".join([inventory, os.path.join(path, "inventory", inventory_file)])
                    inventory.append('-i')
                    inventory.append(os.path.join(path, "inventory", inventory_file))

    return inventory


def load_playbook_vault_file(path):

    vault_password = ['--vault-password-file']

    if os.path.exists(path) and os.path.isdir(path):
        if "vault" in os.listdir(path):
            files_list = [file for file in os.listdir(os.path.join(path, "vault")) if os.path.isfile(os.path.join(path, "vault", file))]
            print(files_list)
            files_count = len(files_list)
            if files_count > 1:
                logger.warning('More than 1 file is possible candidate for ansible vault password. This may lead to playbook execution failure.')
                vault_password.append(os.path.join(path, 'vault', files_list[0]))
                #vault_password = f"--vault-password-file {os.path.join(path, 'vault', files_list[0])}"
                logger.warning(f"First found file {os.path.join(path, 'vault', files_list[0])} will be used for vault password")
            else:
                vault_password.append(os.path.join(path, 'vault', files_list[0]))
                #vault_password = f"--vault-password-file {os.path.join(path, 'vault', files_list[0])}"
                logger.info(f"Ansible vault password will be loaded from file {os.path.join(path, 'vault', files_list[0])}")

    return vault_password


def load_playbook_vars_files(path):

    var_files = []

    if os.path.exists(path) and os.path.isdir(path):
        if "vars" in os.listdir(path) and os.path.isdir(os.path.join(path, "vars")):
            if "configmap" in os.listdir(os.path.join(path, "vars")) and os.path.isdir(os.path.join(path, "vars", "configmap")):
                for var_file in os.listdir(os.path.join(path, "vars", "configmap")):
                    if os.path.isfile(os.path.join(path, 'vars', "configmap", var_file)):
                        #var_files = " -e @".join([var_files, os.path.join(path, "vars", "configmap", var_file)])
                        var_files.append('-e')
                        var_files.append(f'@{os.path.join(path, "vars", "configmap", var_file)}')
            if "secret" in os.listdir(os.path.join(path, "vars")) and os.path.isdir(os.path.join(path, "vars", "secret")):
                for var_file in os.listdir(os.path.join(path, "vars", "secret")):
                    if os.path.isfile(os.path.join(path, 'vars', "secret", var_file)):
                        #var_files = " -e @".join([var_files, os.path.join(path, "vars", "secret", var_file)])
                        var_files.append('-e')
                        var_files.append(f'@{os.path.join(path, "vars", "secret", var_file)}')
            if "vars-configmap" in os.listdir(os.path.join(path, "vars")) and os.path.isdir(os.path.join(path, "vars", "vars-configmap")):
                for var_file in os.listdir(os.path.join(path, "vars", "vars-configmap")):
                    if os.path.isfile(os.path.join(path, 'vars', "vars-configmap", var_file)):
                        #var_files = " -e @".join([var_files, os.path.join(path, "vars", "vars-configmap", var_file)])
                        var_files.append('-e')
                        var_files.append(f'@{os.path.join(path, "vars", "vars-configmap", var_file)}')
    return var_files


def load_playbook_options(path):

    options = []

    if os.path.exists(path) and os.path.isdir(path):
        if "options" in os.listdir(path) and os.path.isdir(os.path.join(path, "options")):
            if "options.list" in os.listdir(os.path.join(path, "options")) and os.path.isfile(os.path.join(path, "options", "options.list")):
                with open(os.path.join(path, "options", "options.list")) as f:
                    for line in f:
                        for word in line.split(' ', 1):
                            options.append(word.strip())

    return options


def load_playbook_path(config, git_path=None, playbook_path=None):
    _git_playbook_name = config.get('git_playbook_name')
    _git_repo_path = config.get('git_repo_path')

    if _git_playbook_name is not None and git_path is not None:
        if _git_repo_path is not None and os.path.isdir(os.path.join(git_path, _git_repo_path)):
            if _git_playbook_name in os.listdir(os.path.join(git_path, _git_repo_path)):
                ansible_playbook_path = os.path.join(git_path, _git_repo_path, _git_playbook_name)
    elif playbook_path is not None and os.path.isdir(playbook_path):
        if "playbook" in os.listdir(playbook_path) and os.path.isdir(os.path.join(playbook_path, "playbook")):
            files_list = [file for file in os.listdir(os.path.join(playbook_path, "playbook")) if os.path.isfile(os.path.join(playbook_path, "playbook", file))]
            files_count = len(files_list)
            if files_count > 1:
                logger.error("More than 1 file is possible candidate for ansible playbook")
                raise RuntimeError
            ansible_playbook_path = os.path.join(playbook_path, "playbook", files_list[0])

    return ansible_playbook_path


def execute_playbook(playbook_path, playbook_options=None, playbook_vars=None, playbook_vault_password=None, playbook_inventory=None):

    #playbook_cmd = playbook_path
    #print(playbook_cmd)

    #if playbook_options is not None:
    #    print(type(playbook_options))
    #    playbook_cmd = " ".join([playbook_cmd, playbook_options])
    #    print(playbook_cmd)
    #if playbook_vars is not None:
    #    print(playbook_vars)
    #    playbook_cmd = " ".join([playbook_cmd, playbook_vars])
    #if playbook_vault_password is not None:
    #    playbook_cmd = " ".join([playbook_cmd, playbook_vault_password])
    #if playbook_inventory is not None:
    #    playbook_cmd = " ".join([playbook_cmd, playbook_inventory])

    #print(playbook_cmd)
    #print(playbook_path)

    playbook = subprocess.run(['ansible-playbook', playbook_path, *playbook_options, *playbook_vars, *playbook_vault_password, *playbook_inventory], capture_output=True)
    logger.info(f'{playbook.returncode}')
    logger.info(f'{playbook.stdout}')
    logger.info(f'{playbook.stderr}')
    logger.info(f'{playbook.args}')


def main():
    config_files = vars(parse_args())
    config_files_list = config_files['config_file']
    config = getConfiguration(config_files_list)

    playbook_config_path = os.environ.get('PLAYBOOK_CONFIG_PATH') or '/opt/config'
    playbook_config_file = os.environ.get('PLAYBOOK_CONFIG_FILE') or 'config.yaml'  # TODO: fix this in operator
    retries = os.environ.get('RETRIES') or 3
    retries_interval = os.environ.get('RETRIES_INTERVAL') or 10
    ssh_username = os.environ.get('SSH_USER_NAME') or 'ansible'
    ssh_keys_path = os.environ.get('SSH_KEYS_PATH') or 'keys'

    _git_requirements_name = config.get('git_requirements_name')
    _git_repo_path = config.get('git_repo_path')

    load_ssh_config(keys_path=os.path.join('/home/', ssh_username, 'keys'))

    clone_git_repo(config, os.path.join(playbook_config_path, 'repo'))

    if "requirements.yaml" in os.listdir(playbook_config_path):
        install_galaxy_requirements(os.path.join(playbook_config_path, "requirements.yaml"))
    if _git_requirements_name is not None and _git_requirements_name in os.listdir(os.path.join(playbook_config_path, "repo", _git_repo_path)):
        install_galaxy_requirements(os.path.join(playbook_config_path, "repo", _git_repo_path, _git_requirements_name))

    inventory = load_playbook_inventory(playbook_config_path)
    vault_password = load_playbook_vault_file(playbook_config_path)
    var_files = load_playbook_vars_files(playbook_config_path)
    options = load_playbook_options(playbook_config_path)
    playbook_path = load_playbook_path(config, git_path=os.path.join(playbook_config_path, 'repo'), playbook_path=playbook_config_path)  # TODO: hadle playbook file load
    execute_playbook(playbook_path, options, var_files, vault_password, inventory)


if __name__ == '__main__':
    main()
