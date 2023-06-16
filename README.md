# Garden Linux Packaging CLI

⚠️ **Warning: This project is currently under development. Use it at your own risk.**

This project provides a package build container, which includes a pyhton cli (the package builder), and all required dependencies.
## Key Features

- The ability to create Garden Linux source packages from original Debian source packages.
- The capability to create Garden Linux packages directly from Git repositories.
- An efficient way to build Garden Linux packages based on source packages.
- All required dependencies and tools for packaging are pre-installed in the Docker container. No need for manual dependency management.

## Prerequisites

- Docker or Podman installed on your machine.
- Python 3.6 or higher.

## Getting Started

Clone the repository:

```bash
git clone https://github.com/yourusername/gardenlinux-packaging-cli.git
cd gardenlinux-packaging-cli
```

Build the Docker image:

```bash
make build
```

You can then use the Docker container to run the CLI commands. Note that the image includes all required tools for packaging, so there is no need to install any additional dependencies on your host system.

## Usage

To use the tool, start the Docker container with the provided wrapper script:

```bash
./package_builder.sh <command> [options]
```

For example, to create a source package from an original Debian source, you can use the `source_debian` command:

```bash
./package_builder.sh source_debian --source_name iproute
```

This command creates a source package for the `iproute` software.

Remember to replace `<command>` with the desired command (`source_git`, `source_debian`, or `build`) and `[options]` with the corresponding options for each command.

## License

This project is licensed under the MIT License - see the [LICENSE.md](./LICENSE.md) file for details.