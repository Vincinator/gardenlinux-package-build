#!/usr/bin/env python3
import click
from common import PackageReleaseType
import source_debian as sd
import build_package as bp
import common as sc

@click.group()
def cli():
    pass

@cli.command()
@click.option('--repo', prompt='Git repository', help='The repository to clone.')
@click.option('--tag-prefix', prompt='Tag prefix', help='Prefix for the tags.')
def source_git(repo, tag_prefix):
    click.echo(f'Repository: {repo}\nTag Prefix: {tag_prefix}')

@cli.command()
@click.option('--distribution', default='trixie', help='The distribution to use.')
@click.option('--source_name', required=True, help='The source name.')
def source_debian(distribution, source_name):
    click.echo(f'Distribution: {distribution}')
    sd.source_from_debian(source_name, distribution, "/workdir", PackageReleaseType.DEV)

@cli.command()
@click.option('--source_name', required=True, help='The source name.')
@click.option('--distribution', default='trixie', help='The distribution to use.')
@click.option('--arch', required=True, help='The target architecture.')
def build(distribution, source_name, arch):
    click.echo(f'Distribution: {distribution}')
    sd.source_from_debian(source_name, distribution, "/workdir", PackageReleaseType.DEV)

    
    # Copy Artifacts from previous source step
    #sc.copy_files("/output/source", "/workdir/source")
    bp.build_package(source_name, distribution, arch,  "/workdir")


if __name__ == '__main__':
    cli()
