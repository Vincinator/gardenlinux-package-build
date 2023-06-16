import subprocess
import os
from enum import Enum
import shutil
from pathlib import Path
import glob

class PackageReleaseType(Enum):
    RELEASE = 1
    DEV = 2

def spawn_bash():
    command = ['bash']
    subprocess.run(command)

def source_from_debian(source_name, source_dist, package_env_path, changelog_type: PackageReleaseType):
    output_dir = "_output"
    overwrite_debian = True
    orig_tar = False 
    
    create_directory(output_dir)
    download_debian_source(source_name, source_dist)
    source_dir_unpacked = extract_source_package(source_name, package_env_path, output_dir)
    copy_debian_folder(package_env_path, source_dir_unpacked, overwrite_debian, orig_tar)
    
    package_version = get_package_version(source_dir_unpacked)
    change_debian_changelog(source_dir_unpacked, changelog_type, package_version)

    spawn_bash()

def create_directory(dir_name):
    os.makedirs(dir_name, exist_ok=True)

def extract_source_package(source_name, root_dir, output_dir):
    # find the .dsc file
    dsc_files = glob.glob(f"{root_dir}/{source_name}_*.dsc")
    if not dsc_files:
        raise FileNotFoundError(f"No .dsc file found for {source_name} in {root_dir}")
    
    # assume the first match is the correct file
    dsc_file = dsc_files[0]

    command = ['dpkg-source', '-x', dsc_file]
    subprocess.run(command, cwd=output_dir, check=True)

    # get the name of the unpacked directory
    source_dir_unpacked = next(Path(output_dir).glob(f"{source_name}-*"))
    return source_dir_unpacked.resolve()

def copy_debian_folder(root_dir, source_dir_unpacked, overwrite_debian=None, orig_tar=None):
    if overwrite_debian or orig_tar:
        debian_dir = Path(root_dir) / 'debian'
        if debian_dir.is_dir():
            print("### Replace debian folder with own content")
            shutil.copytree(debian_dir, source_dir_unpacked / 'debian', dirs_exist_ok=True)


def build_debian_source_package():
    command = ['dpkg-buildpackage', '-us', '-uc', '-S', '-nc', '-d']
    subprocess.run(command, check=True)

def commit_debian_package():
    command = ['dpkg-source', '--commit', '.', 'gardenlinux-changes']
    env = os.environ.copy()
    env['EDITOR'] = 'true'
    subprocess.run(command, env=env, check=True)

def download_debian_source(source_name, source_dist):
    apt_name=f"{source_name}/{source_dist}"
    command = ['apt', 'source', '--only-source', '-d', apt_name]
    subprocess.run(command, check=True)

def get_package_version(package_directory):
    command = ['dpkg-parsechangelog', '-SVersion']
    version = subprocess.check_output(command, cwd=package_directory)
    return version.strip().decode('utf-8')

def change_debian_changelog(source_dir, changelog_type: PackageReleaseType, version, postfix="dev"):
    if changelog_type == PackageReleaseType.RELEASE:
        command = ['dch', '--newversion', version, '--distribution', 'gardenlinux', 
                   '--force-distribution', '--', 'Rebuild for Garden Linux.']
    else:  # ChangelogType.DEV
        command = ['dch', '--newversion', version, '--distribution', 'UNRELEASED', 
                   '--force-distribution', '--', 'Rebuild for Garden Linux.',
                   f"Snapshot from local."]
    
    subprocess.run(command, cwd=source_dir, check=True)