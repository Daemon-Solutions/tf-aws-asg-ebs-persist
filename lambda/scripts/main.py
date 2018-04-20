#!/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function

import boto3
import botocore
import datetime
import dateutil
import json
import logging

from ConfigParser import SafeConfigParser


logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client('ec2')
route53 = boto3.client('route53')
asg = boto3.client('autoscaling')


def retrieve_instance_infos(instanceid):
    """ Return a dict of instance infos.
        Example: {"az": xx,
                  "vpc_id": xxx,
                  "private_ip": xxx,
                  "disks_attach": ["/dev/..", "/dev/..."]}

        :param instanceid string The id of the new instance.
        :return dict
    """
    try:
        instance = ec2.describe_instances(InstanceIds=[instanceid])
        disks = [v['DeviceName'] for v in instance['Reservations'][0]['Instances'][0]['BlockDeviceMappings']]
        return {
            "az": instance['Reservations'][0]['Instances'][0]['Placement']['AvailabilityZone'],
            "disks_attach": disks,
            "vpc_id": instance['Reservations'][0]['Instances'][0]['NetworkInterfaces'][0]['VpcId'],
            "private_ip": instance['Reservations'][0]['Instances'][0]['NetworkInterfaces'][0]['PrivateIpAddress']
        }
    except botocore.exceptions.ClientError as e:
        logger.error("Instance: {0} not found! Exception: {1}" .format(instanceid, str(e.message)))
    except Exception as e:
        logger.error("Can\'t execute search instance operation. Instance informations: {0}. Exception: {1}" .format(str(instance), str(e)))
    return {}


def find_ebs_volume(filters, az):
    """ Return a dict of informations about the volume ID only if
        it respect the parameters values and if it is not currently attached.
        In other case returns an empty dict.

        :param  filters  dict: The tag name and tag value used to filter EBS
                               volumes.
        :param  az   string: The AZ of the EBS volume(format ex: eu-west-1a)
        :return dict Example: {'id': xx, 'size': xx, 'type':xxx, 'iops': xxx}
    """
    iops = 0
    volume_info = ec2.describe_volumes(Filters=[filters])
    for volume in volume_info['Volumes']:
        volume_to_delete = [v for v in volume['Tags'] if v['Key'] == 'ToDelete']
        if volume['State'] == 'available' and volume['AvailabilityZone'] == az and not volume_to_delete:
            if volume['VolumeType'] == 'io1':
                iops = volume['Iops']
            return {'id': volume['VolumeId'], 'size': volume['Size'],
                    'type': volume['VolumeType'], 'iops': iops,
                    'encrypted': volume['Encrypted']}
    return {}


def attach_ebs_volume(volume_id, instance_id, mount_point='/dev/sdp'):
    """ Attach the volume in parameter to the instance.

        :param  volume_id  string: The volume id to attach.
        :param  instance_id  string: The instance id
        :return Bool True if the operation succeed
    """
    instance_running = check_the_resource_state('instance_running', 'InstanceIds', instance_id)
    vol_available = check_the_resource_state('volume_available', 'VolumeIds', volume_id)
    if instance_running and vol_available:
        try:
            ec2.attach_volume(VolumeId=volume_id, InstanceId=instance_id, Device=mount_point)
            return check_the_resource_state('volume_in_use', 'VolumeIds', volume_id)
        except Exception as e:
            logger.error("Attach volume error: {0}" .format(str(e)))
    return False


def check_the_resource_state(wait_type, resource_name, resource_id, max_retry=120):
    """ Return True only if the resource is ready(no operation in progress).

        To list all available waiters: ec2.waiter_names

        :param  resource_name  string: The resouce name to wait(ex:VolumeIds,
                                       SnapshotIds)
        :param  resource_id  string: The resource id to check.
        :param  wait_type  string: The waiter name.
        :param  max_retry  int: The number of retry to perform before to exit.
        :return Bool True if the operation succeed
    """
    waiter = ec2.get_waiter(wait_type)
    waiter.config.delay = 1
    waiter.config.max_attempts = max_retry
    try:
        waiter.wait(**{resource_name: [resource_id]})
        logger.info('Resource {} is ready'.format(resource_id))
    except botocore.exceptions.WaiterError as error:
        logger.error('Checking state of {} failed: [{}]'.format(resource_id, error))
        return False
    return True


def create_ebs_volume(tags, az, volume_type, volume_size, iops, encrypted, snap_id=None):
    """ Create a new EBS volume, tag it and returns the EBS id.

        :param  tags  dict: The tag name and tag value used to filter EBS
                            volumes.
        :param  az    string: The AZ where to create the volume.
        :param  encrypted bool: Enable encryption of the volume.
        :param  volume_type  string: The type of volume to create(ex:GP2)
        :param  volume_size  int: The size(GB) of the new volume to create.
        :param  Iops  string: The number of Iops to provision.
        :param  SnapshotId  string: The snapshot id to use during the create
                                    operation.
        :return string:  The id of the new volume.
    """
    try:
        if snap_id:
            if iops:
                volume_id = ec2.create_volume(Size=int(volume_size),
                                              AvailabilityZone=az,
                                              Encrypted=encrypted,
                                              VolumeType=volume_type,
                                              Iops=iops,
                                              SnapshotId=snap_id)['VolumeId']
            else:
                volume_id = ec2.create_volume(Size=int(volume_size),
                                              AvailabilityZone=az,
                                              Encrypted=encrypted,
                                              VolumeType=volume_type,
                                              SnapshotId=snap_id)['VolumeId']
        else:
            if iops:
                volume_id = ec2.create_volume(Size=int(volume_size),
                                              AvailabilityZone=az,
                                              Encrypted=encrypted,
                                              VolumeType=volume_type,
                                              Iops=iops)['VolumeId']
            else:
                volume_id = ec2.create_volume(Size=int(volume_size),
                                              AvailabilityZone=az,
                                              Encrypted=encrypted,
                                              VolumeType=volume_type)['VolumeId']
        if check_the_resource_state('volume_available',
                                    'VolumeIds',
                                    volume_id):
            ec2.create_tags(Resources=[volume_id], Tags=tags)
            return volume_id
        else:
            logger.error("Timeout while waiting for the availability of the new volume")
    except botocore.exceptions.ClientError as e:
        logger.error("Can\'t create new volume" .format(str(e)))
    except Exception as e:
        logger.error("Can\'t execute volume creation. Exception: {0}" .format(str(e)))
    return None


def check_snapshot_exist(volume_id, time_limit):
    """ Return a snapshot id if a snapshot exists for the volume id in parameter
        and if it was created in the latest time_limit value (in minutes).

        :param  volume_id  string: The volume id to attach.
        :param  time_limit  string: The time delta limit in minutes between now
                                    and the snapshot creation date.
        :return string  The  snapshot id
    """
    snap_ids = ec2.describe_snapshots(Filters=[{'Name': 'volume-id',
                                                'Values': [volume_id]}])['Snapshots']
    for snap in snap_ids:
        if int((datetime.datetime.now(dateutil.tz.tzutc()) - snap['StartTime']).seconds) < (time_limit * 60):
            if check_the_resource_state('snapshot_completed',
                                        'SnapshotIds',
                                        snap["SnapshotId"]):
                return snap['SnapshotId']
    return None


def create_snapshot_if_not_exist(volume_id, tags, time_limit):
    """ Create a snapshot of the volume in parameter only if any snapshot
        exists for this volume_id and if it was created in the time delta
        define by the difference between now and the time_limit value (in
        minutes).

        :param  volume_id  string: The volume id to attach.
        :param  time_limit  string: The time delta limit in minutes between now
                                    and the snapshot creation date.
        :return string  The  snapshot id
    """
    try:
        snap = check_snapshot_exist(volume_id, time_limit)
        if snap:
            logger.info("An existing snapshot was found: {0}" .format(snap))
            return snap
        logger.info("Launch of the snapshot creation process")
        snapshot_id = ec2.create_snapshot(VolumeId=volume_id,
                                          Description='Snapshot create to scale the volume: {0}' .format(volume_id))['SnapshotId']
        ec2.create_tags(Resources=[snapshot_id], Tags=tags)
        logger.info("Waiting until the snapshot become available")
        if not check_the_resource_state('snapshot_completed',
                                        'SnapshotIds',
                                        snapshot_id):
            logger.error("Snapshot still not available, timeout reached")
            return None
        tags = [{'Key': "To_Delete", 'Value': "True"}]
        ec2.create_tags(Resources=[volume_id], Tags=tags)
        return snapshot_id
    except Exception as e:
        logger.error('Can\'t create snapshot: {0}' .format(str(e)))


def manage_ebs_volume(config, instanceid, instance_infos):
    """ Manage the whole EBS process

        :param  ebs_config  dict  The EBS parameters
            -  tags  dict: The tag name and tag value to set if a new EBS
                           volumes is created.
            -  filters  dict: The tag name and tag value used to filter EBS
                              volumes.
            -  volume_type  string: The type of volume to create(ex:GP2)
            -  volume_size  int: The size(GB) of the new volume to create.
            -  time_limit  string: The time delta limit in minutes between now
                                   and the snapshot creation date.
        :param instance_infos  dict {"az": xx, "vpc_id": xxx, "private_ip": xxx,
                                    "disks_attach": ["/dev/..", "/dev/..."]}
        :return Bool
    """
    ebs_infos = find_ebs_volume(config['filters'], instance_infos['az'])
    if (ebs_infos and int(ebs_infos['size']) == int(config['volume_size']) and
            ebs_infos['type'] == config['volume_type'] and
            int(ebs_infos['iops']) == int(config['volume_iops']) and
            ebs_infos['encrypted'] == config['encrypted']):
        ebs_id = ebs_infos['id']
    elif ebs_infos:
        new_vol_infos = {
            "size": config['volume_size'],
            "type": config['volume_type'],
            "iops": config['volume_iops'],
            'encrypted': config['encrypted']
        }
        logger.debug("Difference found between the EBS parameters: {0} request and the EBS volume running: {1}" .format(new_vol_infos, ebs_infos))
        if int(new_vol_infos["size"]) < int(ebs_infos["size"]) and ebs_infos['type'] == config['volume_type']:
            logger.error("Can\'t continue because the new volume size must be greater than the current")
            return False
        elif new_vol_infos['encrypted'] != ebs_infos['encrypted']:
            logger.error("Can\'t continue because volume encryption cannot be modfied after volume creation")
            return False
        snap_id = create_snapshot_if_not_exist(ebs_infos['id'],
                                               config['tags'],
                                               config['time_limit'])
        if snap_id:
            ebs_id = create_ebs_volume(config['tags'],
                                       instance_infos['az'],
                                       config['volume_type'],
                                       config['volume_size'],
                                       config['volume_iops'],
                                       config['encrypted'],
                                       snap_id)
        else:
            logger.error("Can\'t create snapshot")
            return False
    else:
        logger.info("No volume available. Launch the creation process")
        ebs_id = create_ebs_volume(config['tags'],
                                   instance_infos['az'],
                                   config['volume_type'],
                                   config['volume_size'],
                                   config['volume_iops'],
                                   config['encrypted'])
    if ebs_id:
        return attach_ebs_volume(ebs_id, instanceid, config['mount_point'])
    return False


def check_if_ebs_already_attached(instanceid, mount_point, instance_infos):
    """ Check if the instance has already a disk attached on the target
        mount point. This check is to avoid the creation of unused EBS or/and
        snapshot resources.

        :param instanceid  string The id of the EC2 instance
        :param mount_point  string  The mount point where the EBS volume must
                                    be attached.
        :param instance_infos  dict {"az": xx,
                                     "vpc_id": xxx,
                                     "private_ip": xxx,
                                     "disks_attach": ["/dev/..", "/dev/..."]}
        :return  Bool True if a disk is already attached on the instance for
                      this mount point.a
    """
    if mount_point in instance_infos["disks_attach"]:
        return True
    return False


def load_configuration_params(parser, section_name):
    """ Return a dict of EBS parameters for this section.

        :param  parser  safeconfigparser object of the config file.
        :param  section_name  string  The name of the section to parse.
        :return  dict  The EBS parameters for this section.
    """
    filters = {'Name': "tag:{0}" .format(parser.get(section_name, 'tag_name')),
               "Values": [parser.get(section_name, 'tag_value')]}
    tags = [{'Key': parser.get(section_name, 'tag_name'),
             'Value': parser.get(section_name, 'tag_value')}]

    extra_tags_string = parser.get(section_name, 'extra_tags')
    extra_tags = json.loads(extra_tags_string)
    for tag_name, tag_value in extra_tags.items():
        tags.append({
            'Key': tag_name,
            'Value': tag_value
        })

    encrypted = parser.get(section_name, 'encrypted').lower() in ['true', '1']
    params = {'volume_size': int(parser.get(section_name, 'volume_size')),
              'volume_type': parser.get(section_name, 'volume_type'),
              'mount_point': parser.get(section_name, 'mount_point'),
              'volume_iops': int(parser.get(section_name, 'volume_iops')),
              'time_limit': parser.get(section_name, 'time_limit'),
              'tags': tags,
              'filters': filters,
              'encrypted': encrypted}
    return params


def launch_ebs_affinity_process(instanceid, instance_infos, ebs_configs):
    """ Manage the ebs affinity process.

        :param  instanceid  string  The instance id
        :param  instance_infos  dict  Informations about the instance
        :param  ebs_config  dict  The EBS parameters
        :return None
    """
    if not check_if_ebs_already_attached(instanceid,
                                         ebs_configs['mount_point'],
                                         instance_infos):
        if manage_ebs_volume(ebs_configs, instanceid, instance_infos):
            logger.info("EBS: {0} has been attached on the Instance-id: {1}" .format(ebs_configs['mount_point'], instanceid))
        else:
            logger.error("Error during the management of the EBS volume: {0}. Disk not attached to the instance: {1} " .format(ebs_configs['mount_point'], instanceid))
            return False
        return True
    else:
        logger.info("A disk is already attached on the target mount point: {0}" .format(ebs_configs['mount_point']))
    return True


def lambda_handler(event, context):
    """ Main function """
    logger.info('Received event: {}'.format(event))

    parser = SafeConfigParser()
    parser.read('lambda_as_ebs.conf')
    result = False

    if 'Records' in event:
        # SNS Message.
        sns_message = json.loads(event['Records'][0]['Sns']['Message'])
        event_type = sns_message['Event']
        asgname = sns_message['AutoScalingGroupName']
        instanceid = sns_message.get('EC2InstanceId')
    else:
        # CloudWatch Event.
        event_type = event['detail']['LifecycleTransition']
        asgname = event['detail']['AutoScalingGroupName']
        instanceid = event['detail']['EC2InstanceId']

    if event_type == 'autoscaling:TEST_NOTIFICATION':
        logger.info('{} for {}'.format(event_type, asgname))
        asginstances = asg.describe_auto_scaling_groups(AutoScalingGroupNames=[asgname])
        logger.info(asginstances)
        for i in asginstances["AutoScalingGroups"][0]["Instances"]:
                logger.info("Detected instance: " + (i["InstanceId"]))
                instanceid = (i["InstanceId"])
                instance_infos = retrieve_instance_infos(instanceid)
                if instance_infos:
                    for section in parser.sections():
                        configs = load_configuration_params(parser, section)
                        logger.info("Launch EBS affinity: " + str(instanceid) + str(instance_infos) + str(configs))
                        result = launch_ebs_affinity_process(instanceid, instance_infos, configs)
                else:
                    logger.error("Can\'t retrieve informations about the instance: " + str(instanceid))
    else:
        logger.info('{} for {} {}'.format(event_type, asgname, instanceid))
        instance_infos = retrieve_instance_infos(instanceid)
        if instance_infos:
            for section in parser.sections():
                configs = load_configuration_params(parser, section)
                logger.info("Launch EBS affinity: " + str(instanceid) + str(instance_infos) + str(configs))
                result = launch_ebs_affinity_process(instanceid, instance_infos, configs)
        else:
            logger.error("Can\'t retrieve informations about the instance: " + str(instanceid))

    # fail it it went wrong
    if not result:
        raise Exception('Failed to attach volume')
