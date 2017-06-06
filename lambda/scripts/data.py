#!/usr/bin/env python

import json
import os
import sys
import shutil
import ConfigParser

# read json
arguments = json.load(sys.stdin)

# dicts
mount_point = json.loads(arguments['mount_point'])
volume_size = json.loads(arguments['volume_size'])
volume_type = json.loads(arguments['volume_type'])
volume_iops = json.loads(arguments['volume_iops'])
tag_value = json.loads(arguments['tag_value'])
encrypted = json.loads(arguments['encrypted'])

# strings
tag_name = arguments['tag_name']
time_limit = arguments['time_limit']
module_path = arguments['module_path']
stack_name = arguments['stack_name']
lambda_version = arguments['lambda_version']

# manage directories
stack_dir = os.path.join(module_path, 'files', stack_name)
if os.path.exists(stack_dir):
    shutil.rmtree(stack_dir)
os.mkdir(stack_dir)

# copy main script
shutil.copyfile(os.path.join(module_path, 'scripts', 'main.py'),
                os.path.join(stack_dir, 'main.py'))

# generate config file
Config = ConfigParser.ConfigParser()
cfgfile = open(os.path.join(stack_dir, 'lambda_as_ebs.conf'), 'w')
for key in mount_point.keys():
    section = mount_point[key]
    Config.add_section(section)
    Config.set(section, 'time_limit', time_limit)
    Config.set(section, 'volume_size', volume_size[key])
    Config.set(section, 'volume_type', volume_type[key])
    Config.set(section, 'volume_iops', volume_iops[key])
    Config.set(section, 'mount_point', mount_point[key])
    Config.set(section, 'tag_name', tag_name)
    Config.set(section, 'tag_value', tag_value[key])
    Config.set(section, 'encrypted', encrypted[key])
Config.write(cfgfile)
cfgfile.close()

# return json
json.dump({"source_dir": stack_dir}, sys.stdout)
