#!/usr/bin/env python

import json
import os
import sys
import shutil
import ConfigParser

arguments = json.load(sys.stdin)


module_path = arguments['module_path']
stack_name = arguments['stack_name']
lambda_version = arguments['lambda_version']
# dicts
mount_point = json.loads(arguments['mount_point'])
volume_size = json.loads(arguments['volume_size'])
volume_type = json.loads(arguments['volume_type'])
volume_iops = json.loads(arguments['volume_iops'])
tag_value = json.loads(arguments['tag_value'])
encrypted = json.loads(arguments['encrypted'])
#string
tag_name = arguments['tag_name']
time_limit = arguments['time_limit']


# manage directories
stack_dir = os.path.join(module_path, 'files', stack_name)
if os.path.exists(stack_dir):
    shutil.rmtree(os.path.join(module_path, 'files', stack_name))
os.mkdir(os.path.join(module_path, 'files', stack_name))
# copy main script
shutil.copyfile(os.path.join(module_path, 'scripts', 'main.py'), os.path.join(module_path, 'files', stack_name, 'main.py'))

Config = ConfigParser.ConfigParser()

cfgfile = open(os.path.join(module_path, 'files', stack_name, 'lambda_as_ebs.conf'), 'w')
for key in mount_point.keys():
    Config.add_section(mount_point[key])
    Config.set(mount_point[key], 'time_limit', time_limit)
    Config.set(mount_point[key], 'volume_size', volume_size[key])
    Config.set(mount_point[key], 'volume_type', volume_type[key])
    Config.set(mount_point[key], 'volume_iops', volume_iops[key])
    Config.set(mount_point[key], 'mount_point', mount_point[key])
    Config.set(mount_point[key], 'tag_name', tag_name)
    Config.set(mount_point[key], 'tag_value', tag_value[key])
    Config.set(mount_point[key], 'encrypted', encrypted[key])
Config.write(cfgfile)
cfgfile.close()

json.dump({
    "source_dir": os.path.join(module_path, 'files', stack_name),
}, sys.stdout)
