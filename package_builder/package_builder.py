#!/usr/bin/env python3
import click
import source_debian as sd

@click.group()
def cli():
    pass

@cli.command()
@click.option('--repo', prompt='Git repository', help='The repository to clone.')
@click.option('--tag-prefix', prompt='Tag prefix', help='Prefix for the tags.')
def source_git(repo, tag_prefix):
    # your function to clone repo and do something with tags
    click.echo(f'Repository: {repo}\nTag Prefix: {tag_prefix}')

@cli.command()
@click.option('--distribution', default='trixie', help='The distribution to use.')
@click.option('--source_name', required=True, help='The source name.')
def source_debian(distribution, source_name):
    # your function to do something with the distribution
    click.echo(f'Distribution: {distribution}')
    sd.source_from_debian(source_name, distribution, "/package", sd.PackageReleaseType.DEV)

@cli.command()
def build():
    # your function to build
    click.echo('Building...')

if __name__ == '__main__':
    cli()
