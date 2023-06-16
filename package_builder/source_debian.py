import subprocess
import os
from enum import Enum
import shutil
from pathlib import Path
import glob
from source_common import delete_folder
import source_common as sc
from source_common import PackageReleaseType, change_debian_changelog, copy_debian_folder, get_package_version


def spawn_bash():
    command = ['bash']
    subprocess.run(command)

def source_from_debian(source_name, source_dist, package_env_path, changelog_type: PackageReleaseType):
    output_dir = "_output"
    overwrite_debian = True
    orig_tar = False 

   
    try:
        create_directory(output_dir)
        download_debian_source(source_name, source_dist)
        source_dir_unpacked = extract_source_package(source_name, package_env_path, output_dir)
        copy_debian_folder(package_env_path, source_dir_unpacked, overwrite_debian, orig_tar)
        
        package_version = get_package_version(source_dir_unpacked)
        change_debian_changelog(source_dir_unpacked, changelog_type, package_version)
    except Exception as e:
        #spawn_bash()
        sc.logger.error("Caught Exception. Cleaning up now.")
        sc.logger.error(e)

        delete_folder(output_dir)


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


def download_debian_source(source_name, source_dist):
    apt_name=f"{source_name}/{source_dist}"
    command = ['apt', 'source', '--only-source', '-d', apt_name]
    subprocess.run(command, check=True)