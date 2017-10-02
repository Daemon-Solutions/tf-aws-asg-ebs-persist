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

# manage directories
stack_dir = os.path.join(module_path, 'files', stack_name)
if os.path.exists(stack_dir):
    shutil.rmtree(stack_dir)
os.mkdir(stack_dir)

# copy main script
shutil.copyfile(os.path.join(module_path, 'scripts', 'main.py'),
                os.path.join(stack_dir, 'main.py'))

# generate config file
config = ConfigParser.ConfigParser()
for key in mount_point.keys():
    section = mount_point[key]
    config.add_section(section)
    config.set(section, 'time_limit', time_limit)
    config.set(section, 'volume_size', volume_size[key])
    config.set(section, 'volume_type', volume_type[key])
    config.set(section, 'volume_iops', volume_iops[key])
    config.set(section, 'mount_point', mount_point[key])
    config.set(section, 'tag_name', tag_name)
    config.set(section, 'tag_value', tag_value[key])
    config.set(section, 'encrypted', encrypted[key])

with open(os.path.join(stack_dir, 'lambda_as_ebs.conf'), 'w') as cfgfile:
    config.write(cfgfile)

# return json
json.dump({"source_dir": stack_dir}, sys.stdout)
