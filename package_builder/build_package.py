import subprocess
import os
from enum import Enum
from pathlib import Path
import glob
from common import delete_folder
import common as sc
from common import PackageReleaseType, change_debian_changelog, copy_debian_folder, get_package_version

import subprocess

arch_dict = {
    'amd64': 'x86_64-linux-gnu',
    'arm64': 'aarch64-linux-gnu',
}



def build_package(source_name, source_dist, arch, workdir):
    overwrite_debian = True
    orig_tar = False 

    try:
        install_build_dependencies(workdir, arch)
        extract_source(workdir)
        do_build(f"{workdir}/src", arch)
    except subprocess.CalledProcessError as e:
        sc.logger.error(f"Subprocess failed:\n{e.stderr.decode()}")
        sc.list_directory_contents(workdir)

    except Exception as e:
        #spawn_bash()
        sc.logger.error("Caught Exception. Cleaning up now.")
        sc.logger.error(e)

        #delete_folder(output_dir)

def extract_source(workdir):
    dsc_file = get_dsc_file(workdir)
    command = ['dpkg-source', '-x', dsc_file, f"{workdir}/src"]
    subprocess.run(command, cwd=workdir,  stderr=subprocess.PIPE, check=True)


def do_build(workdir, target_arch):
    dpkg_arch = subprocess.run(['dpkg', '--print-architecture'], capture_output=True, text=True).stdout.strip()

    if target_arch != dpkg_arch:
        if "DEB_BUILD_OPTIONS" not in os.environ:
            os.environ["DEB_BUILD_OPTIONS"] = "nocheck"
        else:
            os.environ["DEB_BUILD_OPTIONS"] += " nocheck"

        if "DEB_BUILD_PROFILES" not in os.environ:
            os.environ["DEB_BUILD_PROFILES"] = "cross"
        else:
            os.environ["DEB_BUILD_PROFILES"] += " cross"

    if target_arch == 'all':
        subprocess.run(["su", "-s", "/bin/sh", "-c", f"set -euE; dpkg-buildpackage -A", "nobody"], cwd=workdir, check=True)
    else:
        subprocess.run(["su", "-s", "/bin/sh", "-c", f"set -euE; dpkg-buildpackage -B -a {target_arch}", "nobody"], cwd=workdir, check=True)



def get_dsc_file(directory_path):
    files = glob.glob(os.path.join(directory_path, "*.dsc"))

    if len(files) > 1:
        raise ValueError("Multiple .dsc files found.")
    elif not files:
        raise ValueError("No .dsc file found.")
    
    return files[0]

def install_build_dependencies(workdir, target_arch, deb_build_profiles=None):
    sc.logger.info(f"Installing build dependencies for arch {target_arch} ...")
    subprocess.run(["apt-get", "upgrade", "-qy", "-o", "DPkg::Options::=--force-unsafe-io", "fakeroot"], stderr=subprocess.PIPE, check=True)
    dsc_file = get_dsc_file(workdir)
    if target_arch == "all":

        subprocess.run(["apt-get", "build-dep", "-qy", "--indep-only", "-o", "DPkg::Options::=--force-unsafe-io", dsc_file], cwd=workdir, stderr=subprocess.PIPE, check=True)
    else:
        gnu_type = arch_dict[target_arch]
        dpkg_arch = subprocess.run(["dpkg", "--print-architecture"], capture_output=True, text=True).stdout.strip()
        if target_arch != dpkg_arch:
            if "DEB_BUILD_PROFILES" not in os.environ:
                os.environ["DEB_BUILD_PROFILES"] = "cross"
            else:
                os.environ["DEB_BUILD_PROFILES"] += " cross"

        subprocess.run(["apt-get", "build-dep", "-qy", "-a", target_arch, "--arch-only", "-o", "DPkg::Options::=--force-unsafe-io", dsc_file], cwd=workdir, stderr=subprocess.PIPE, check=True)

        # Workaround for non-multiarch build-essential, see https://bugs.debian.org/666743
        subprocess.run(["apt-get", "install", "-qy", "--no-install-recommends", f"binutils-{gnu_type}", f"gcc-{gnu_type}", f"g++-{gnu_type}", f"libc6-dev:{target_arch}"], cwd=workdir, stderr=subprocess.PIPE, check=True)
