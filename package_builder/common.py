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

def chown_nobody(target_dir):
    command = ['sudo', 'chown',  'nobody', '-R', '.']
    subprocess.run(command, cwd=target_dir, check=True)

def copy_debian_folder(workdir, source_dir, overwrite_debian=None, orig_tar=None):
    pass

def copy_file(src, dest, use_sudo=False):
    if use_sudo:
        logger.info(f"Copy {src} to {dest} ...")
        subprocess.run(['sudo', 'cp', src, dest], check=True)
    else:
        logger.info(f"Copy {src} to {dest} ...")
        shutil.copy2(src, dest)

def copy_directory(src, dest, files_only=False, use_sudo=False):
        if files_only:
            for filename in os.listdir(src):
                file_path = os.path.join(src, filename)
                if os.path.isfile(file_path):
                    copy_file(file_path, dest, use_sudo)
        else:
            if use_sudo:
                logger.info(f"sudo copy {src} to {dest} ...")
                subprocess.run(['sudo', 'cp', '-r', src, dest], check=True)
            else:
                logger.info(f"copy {src} to {dest} ...")
                shutil.copytree(src, dest)
   

def copy_files(src_folder, dest_folder, permissions='non-sudo', files_only=False):
    use_sudo = permissions == 'sudo'

    if not os.path.exists(dest_folder):
        create_directory(dest_folder)

    if '*' in src_folder:
        files = glob.glob(src_folder)
        for file in files:
            if os.path.isfile(file):
                logger.info(f"{file} is a file, copy file now")
                copy_file(file, dest_folder, use_sudo)
            elif os.path.isdir(file):
                logger.info(f"{file} is a folder, copy folder now")
                copy_directory(file, dest_folder, files_only, use_sudo)
    elif os.path.isfile(src_folder):
        logger.info(f"{src_folder} is a file, copy file now")
        copy_file(src_folder, dest_folder, use_sudo)
    elif os.path.isdir(src_folder):
        logger.info(f"{src_folder} is a folder, copy folder now")
        copy_directory(src_folder, dest_folder, files_only, use_sudo)
    else:
        logger.warning(f"Source path {src_folder} does not exist")


def build_debian_source_package(source_dir):
    logger.info("Build source package")
    command = ['sudo', 'dpkg-buildpackage', '-us', '-uc', '-S', '-nc', '-d']
    subprocess.run(command, cwd=source_dir, check=True)

def commit_debian_package():
    logger.info("Commit changes to source package")
    command = ['sudo', 'dpkg-source', '--commit', '.', 'gardenlinux-changes']
    env = os.environ.copy()
    env['EDITOR'] = 'true'
    env['DEBEMAIL'] = GARDENLINUX_DEBMAIL
    env['DEBFULLNAME'] = GARDENLINUX_FULL_NAME

    subprocess.run(command, env=env, check=True)


def get_package_version(package_directory):
    logger.info("Get Package Version")
    command = ['sudo', 'dpkg-parsechangelog', '-SVersion']
    version = subprocess.check_output(command, cwd=package_directory)

    return version.strip().decode('utf-8')

def create_directory(dir_name):
    try:
        subprocess.check_call(['sudo', 'mkdir', '-p', dir_name])
    except subprocess.CalledProcessError as e:
        print(f"Failed to create directory {dir_name}: {str(e)}")
        raise e
    
def change_debian_changelog(source_dir, changelog_type: PackageReleaseType, version, postfix="dev"):
    env = os.environ.copy()
    env['DEBEMAIL'] = GARDENLINUX_DEBMAIL
    env['DEBFULLNAME'] = GARDENLINUX_FULL_NAME
    if changelog_type == PackageReleaseType.RELEASE:
        logger.info("Add release entry to changelog")
        command = ['sudo', 'dch', '--newversion', version, '--distribution', 'gardenlinux', 
                   '--force-distribution', '--', 'Rebuild for Garden Linux.']
    else:  # ChangelogType.DEV
        logger.info("Add dev entry to changelog")
        command = ['sudo', 'dch', '--newversion', version, '--distribution', 'UNRELEASED', 
                   '--force-distribution', '--', 'Rebuild for Garden Linux.',
                   f"Snapshot from local."]
    
    subprocess.run(command, env=env, cwd=source_dir, check=True)