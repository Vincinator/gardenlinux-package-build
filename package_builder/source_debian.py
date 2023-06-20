import subprocess
import os
from enum import Enum
from pathlib import Path
import glob
from common import delete_folder
import common as sc
from common import PackageReleaseType, change_debian_changelog, copy_debian_folder, get_package_version


def spawn_bash():
    command = ['bash']
    subprocess.run(command)

def source_from_debian(source_name, source_dist, workdir, changelog_type: PackageReleaseType):
    overwrite_debian = True
    orig_tar = False 

    try:
        sc.create_directory(workdir)
        download_debian_source(workdir, source_name, source_dist)
        source_dir_unpacked = extract_source_package(workdir, source_name)
        copy_debian_folder(workdir, source_dir_unpacked, overwrite_debian, orig_tar)
        
        package_version = get_package_version(source_dir_unpacked)
        change_debian_changelog(source_dir_unpacked, changelog_type, package_version)
        sc.build_debian_source_package(source_dir_unpacked)
        sc.copy_files(f"/workdir", "/output", permissions="sudo", files_only=True)
    except Exception as e:
        #spawn_bash()
        sc.logger.error("Caught Exception. Cleaning up now.")
        sc.logger.error(e)
        exit(1)
        #delete_folder(workdir)




def extract_source_package(workdir, source_name):
    # find the .dsc file
    dsc_files = glob.glob(f"{workdir}/{source_name}_*.dsc")
    if not dsc_files:
        raise FileNotFoundError(f"No .dsc file found for {source_name} in {workdir}")
    
    # assume the first match is the correct file
    dsc_file = dsc_files[0]

    command = ['sudo', 'dpkg-source', '-x', dsc_file]
    subprocess.run(command, cwd=workdir, check=True)

    # get the name of the unpacked directory
    source_dir_unpacked = next(Path(workdir).glob(f"{source_name}-*"))
    return source_dir_unpacked.resolve()


def download_debian_source(output_dir, source_name, source_dist):
    apt_name=f"{source_name}/{source_dist}"
    command = ['sudo', 'apt', 'source', '--only-source', '-d', apt_name]
    subprocess.run(command, cwd=output_dir, check=True)