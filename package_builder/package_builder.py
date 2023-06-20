#!/usr/bin/env python3
import click
from common import PackageReleaseType
import source_debian as sd
import build_package as bp
import common as sc
import os
@click.group()
def cli():
    pass

@cli.command()
@click.argument('source_name')
@click.option('--repository_url', prompt='Git repository', help='The repository to clone.')
@click.option('--git_tag', prompt='Git tag', help='Git tag to checkout')
def source_git(source_name, repository_url, git_tag):
    click.echo(f'Repository: {repository_url}\nTag Prefix: {git_tag}')

@cli.command()
@click.option('--distribution', default='trixie', help='The distribution to use.')
@click.option('--source_name', required=True, help='The source name.')
def source_debian(distribution, source_name):
    click.echo(f'Distribution: {distribution}')
    sd.source_from_debian(source_name, distribution, "/workdir", PackageReleaseType.DEV)

@cli.command()
@click.option('--arch', required=True, help='The target architecture.')
def build(arch):
    if not os.path.exists("/input"):
        click.echo(f"No source package found in /input/source directory. Aborting...")
        exit(1)
    sc.copy_directory("/input", "/workdir", use_sudo="sudo")
    sc.list_directory_contents("/workdir")
    bp.build_package(arch, "/workdir")


if __name__ == '__main__':
    cli()
