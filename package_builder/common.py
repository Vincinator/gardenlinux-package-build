import subprocess
import os
from enum import Enum
import shutil
from pathlib import Path
import glob
import logging

class PackageReleaseType(Enum):
    RELEASE = 1
    DEV = 2

GARDENLINUX_FULL_NAME="Garden Linux builder"
GARDENLINUX_DEBMAIL="contact@gardenlinux.io"

logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

def list_directory_contents(directory_path):
    try:
        contents = os.listdir(directory_path)
        print(f"Contents of the directory {directory_path}:")
        for item in contents:
            print(item)
    except FileNotFoundError:
        print(f"The directory {directory_path} does not exist.")

def delete_folder(folder_path):
    try:
        shutil.rmtree(folder_path)
    except Exception as e:
        print(f"Error removing folder '{folder_path}': {str(e)}")


def copy_debian_folder(workdir, source_dir, overwrite_debian=None, orig_tar=None):
    if overwrite_debian or orig_tar:
        debian_dir = Path(workdir) / 'debian'
        if debian_dir.is_dir():
            logger.info("Replace debian folder with own content")
            shutil.copytree(debian_dir, source_dir / 'debian', dirs_exist_ok=True)


def copy_files(source_dir, dest_dir):
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)

    for filename in os.listdir(source_dir):
        filepath = os.path.join(source_dir, filename)

        if os.path.isfile(filepath):
            shutil.copy(filepath, dest_dir)

def build_debian_source_package(source_dir):
    logger.info("Build source package")
    command = ['dpkg-buildpackage', '-us', '-uc', '-S', '-nc', '-d']
    subprocess.run(command, cwd=source_dir, check=True)

def commit_debian_package():
    logger.info("Commit changes to source package")
    command = ['dpkg-source', '--commit', '.', 'gardenlinux-changes']
    env = os.environ.copy()
    env['EDITOR'] = 'true'
    env['DEBEMAIL'] = GARDENLINUX_DEBMAIL
    env['DEBFULLNAME'] = GARDENLINUX_FULL_NAME

    subprocess.run(command, env=env, check=True)


def get_package_version(package_directory):
    logger.info("Get Package Version")
    command = ['dpkg-parsechangelog', '-SVersion']
    version = subprocess.check_output(command, cwd=package_directory)

    return version.strip().decode('utf-8')

def change_debian_changelog(source_dir, changelog_type: PackageReleaseType, version, postfix="dev"):
    env = os.environ.copy()
    env['DEBEMAIL'] = GARDENLINUX_DEBMAIL
    env['DEBFULLNAME'] = GARDENLINUX_FULL_NAME
    if changelog_type == PackageReleaseType.RELEASE:
        logger.info("Add release entry to changelog")
        command = ['dch', '--newversion', version, '--distribution', 'gardenlinux', 
                   '--force-distribution', '--', 'Rebuild for Garden Linux.']
    else:  # ChangelogType.DEV
        logger.info("Add dev entry to changelog")
        command = ['dch', '--newversion', version, '--distribution', 'UNRELEASED', 
                   '--force-distribution', '--', 'Rebuild for Garden Linux.',
                   f"Snapshot from local."]
    
    subprocess.run(command, env=env, cwd=source_dir, check=True)