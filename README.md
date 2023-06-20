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
git clone https://github.com/vinciantor/gardenlinux-packaging-cli.git
cd gardenlinux-packaging-cli
```

Build the Docker image:

```bash
make build
```

You can then use the Docker container to run the CLI commands. Note that the image includes all required tools for packaging, so there is no need to install any additional dependencies on your host system.

## Usage

`pbcli` provides a convenient command line interface for building and deploying packages. Here's an example of how you might use it:

```
pbcli.py source iproute2 trixie debian
pbcli.py build all
```

In this example, the `source` command is used to create a source package. This command takes three arguments:

1. The name of the source package (`iproute2` in this example).
2. The distribution (`trixie` in this example).
3. The type of the package (`debian` in this example to download sources from debian, but can also be `git`).

By default, the output from this command will be placed in the `output/source` directory.

The `build` command is then used to build binary packages from the source package. This command takes one argument, which specifies the architecture to build for (`all` in this example).

By default, the `build` command expects to find the source package in the `output/source` directory. However, you can also provide a custom path to the source package if you prefer. Once the build process is complete, the binary packages will be placed in the `output/binary` directory.

Please note that the `build` command requires that the source package exists in the `output/source` directory or in the custom path you provide. If it cannot find the source package, it will not be able to build the binary packages.

---

## License

This project is licensed under the MIT License - see the [LICENSE.md](./LICENSE.md) file for details.