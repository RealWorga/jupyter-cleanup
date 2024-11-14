# Jupyter Cleanup

[![ShellCheck](https://github.com/RealWorga/jupyter-cleanup/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/RealWorga/jupyter-cleanup/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Clean up stale Jupyter processes and files on Linux servers. Handles process termination, runtime cleanup, and environment verification.

## Install
```bash
git clone https://github.com/RealWorga/jupyter-cleanup
cd jupyter-cleanup
chmod +x src/cleanup.sh src/lib/*.sh
```

## Use
```bash
./src/cleanup.sh
```

Logs: `~/.local/state/jupyter-cleanup/cleanup-YYYYMMDD.log`

## Features
- Safe process termination
- Runtime file cleanup
- Path auto-detection
- Error recovery
- Cross-distro support

## Test
```bash
./tests/test_paths.sh
./tests/test_process.sh
./tests/test_system.sh
```

## Compatibility
- Ubuntu 18.04+
- CentOS/RHEL 7+
- Debian 10+

## License
[MIT](LICENSE)