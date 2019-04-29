#!/usr/bin/env python

import json
import os
import sys
import shutil
import configparser

# read json
arguments = json.load(sys.stdin)

# dicts
mount_point = json.loads(arguments['mount_point'])
volume_size = json.loads(arguments['volume_size'])
volume_type = json.loads(arguments['volume_type'])
volume_iops = json.loads(arguments['volume_iops'])
tag_value = json.loads(arguments['tag_value'])
extra_tags = json.loads(arguments['extra_tags'])
encrypted = json.loads(arguments['encrypted'])

# strings
tag_name = arguments['tag_name']
time_limit = arguments['time_limit']
module_path = arguments['module_path']
asg_name = arguments['asg_name']
aws_acccount_id = arguments['aws_acccount_id']

# manage directories
asg_dir = os.path.join(module_path, 'files', aws_acccount_id + '-' + asg_name)
if os.path.exists(asg_dir):
    shutil.rmtree(asg_dir)
os.mkdir(asg_dir)

# copy main script
shutil.copyfile(os.path.join(module_path, 'scripts', 'main.py'),
                os.path.join(asg_dir, 'main.py'))

# generate config file
config = configparser.ConfigParser()
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

    tags = {}
    for extra_tag_name, extra_tag_value in extra_tags.items():
        if extra_tag_name.startswith(key + '.'):
            tags[extra_tag_name.split('.', 1)[1]] = extra_tag_value
    # ConfigParser doesn't support nested dictionaries, so we serialize tags in JSON
    config.set(section, 'extra_tags', json.dumps(tags))


with open(os.path.join(asg_dir, 'lambda_as_ebs.conf'), 'w') as cfgfile:
    config.write(cfgfile)

# return json
json.dump({"source_dir": asg_dir}, sys.stdout)
