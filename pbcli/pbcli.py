#!/usr/bin/env python3

import os
import subprocess
import click

IMAGE_NAME = "package-builder"

@click.group()
def cli():
    pass

def run_in_container(args, input_dir, output_dir):
    container_run_opts = [
        "--security-opt", "seccomp=unconfined",
        "--security-opt", "apparmor=unconfined",
        "--security-opt", "label=disable",
    ]

    container_mount_opts = [
        "-v", f"{output_dir}:/output",
    ]

    if input_dir and os.path.isdir(input_dir):
        container_mount_opts.extend(["-v", f"{input_dir}:/input"])

    os.makedirs(output_dir, exist_ok=True)
    subprocess.run(["podman", "run", *container_run_opts, *container_mount_opts, IMAGE_NAME, *args])


@cli.command()
@click.argument('source_name')
@click.argument('type', type=click.Choice(['debian', 'git'], case_sensitive=False))
@click.option('--distribution', default="testing", help="Distribution name")
@click.option('--repository_url', default=None, help="Repository URL (required if type is 'git').")
@click.option('--git_tag', default=None, help="Git tag string (required if type is 'git').")
@click.option('--output-dir', default="output/source", show_default=True, help="Output directory.")
def source(source_name, type, distribution, repository_url, git_tag, output_dir):
    if type == 'git' and (not repository_url or not git_tag):
        raise click.BadParameter("The 'repository_url' and 'git_tag' parameters are required when source type is 'git'.")
    
    args = [f"source-{type}", "--source_name", source_name]
    if type == "debian":
        args.extend(["--distribution", distribution])
    else:
        args.extend(["--repository_url", repository_url, "--git_tag", git_tag])
    
    run_in_container(args, None, os.path.abspath(output_dir))


@cli.command()
@click.argument('architecture')
@click.option('--input-dir', default="output/source", show_default=True, help="Input directory.")
@click.option('--output-dir', default="output/binary", show_default=True, help="Output directory.")
def build(architecture, input_dir, output_dir):
    run_in_container([f"build", "--arch", architecture], os.path.abspath(input_dir), os.path.abspath(output_dir))

@cli.command()
@click.argument('source_name')
@click.option('--input-directory', default="output/binary", show_default=True, help="Input directory.")
def deploy(source_name, input_directory):
    print(f"source_name={source_name}, input_directory={input_directory}")

if __name__ == '__main__':
    cli()
