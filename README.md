# Jupyter Cleanup

[![ShellCheck](https://github.com/RealWorga/jupyter-cleanup/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/RealWorga/jupyter-cleanup/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Cleanup utility for Jupyter environments on Linux servers.

## Features

- Process management with graceful termination
- Runtime file cleanup with path detection
- Cross-distribution compatibility
- Detailed logging with diagnostics
- Error recovery and self-healing

## Installation

```bash
git clone https://github.com/RealWorga/jupyter-cleanup
cd jupyter-cleanup
chmod +x src/cleanup.sh
```

## Usage

```bash
./src/cleanup.sh
```

Logs are stored in `~/.local/state/jupyter-cleanup/`.

## Server Compatibility

Tested on:
- Ubuntu Server 18.04+
- CentOS 7/8
- RHEL 7/8/9
- Scientific Linux 7
- Debian 10+

## Development

```bash
# Run tests
./tests/test_paths.sh
./tests/test_process.sh
./tests/test_system.sh

# Check code
shellcheck src/*.sh src/lib/*.sh
```

## License

MIT