# mediainfo-downloader

Downloads [MediaInfo](https://mediaarea.net/en/MediaInfo) CLI binary and shared library (`libmediainfo.so`) pre-built for AWS Lambda.

Binaries are sourced from the official [MediaArea Lambda builds](https://mediaarea.net/en/MediaInfo/Download/Lambda).

## Requirements

- `curl`
- `unzip`

## Usage

```sh
./mediainfo-downloader.sh [OPTIONS]
```

### Options

| Flag | Alias | Default | Description |
|------|-------|---------|-------------|
| `--version` | `-v` | `release` | `release` for latest, or specific version e.g. `25.10` |
| `--architecture` | `-a` | `amd64` | `amd64` / `x86_64` or `arm64` / `aarch64` |
| `--dir` | `-d` | `mediainfo-bin` | Directory where the `mediainfo` binary is placed |
| `--lib-dir` | `-l` | _(unset)_ | If set, also downloads `libmediainfo.so` to this directory |
| `--cleanup` | `-c` | `false` | Remove downloaded archives after extraction |
| `--help` | `-h` | | Print usage |

## Examples

**Download latest CLI binary for arm64:**
```sh
./mediainfo-downloader.sh --dir /opt --architecture arm64
```

**Download latest CLI + library for arm64:**
```sh
./mediainfo-downloader.sh --dir /opt --lib-dir /opt/lib --architecture arm64
```

**Download specific version (CLI + library) for amd64:**
```sh
./mediainfo-downloader.sh --version 25.10 --dir /opt --lib-dir /opt/lib --architecture amd64
```

**Download latest for x86_64 (alias for amd64):**
```sh
./mediainfo-downloader.sh --architecture x86_64 --dir /opt/bin
```

## Output structure

After extraction the files are placed flat in the specified directories:

```
/opt/
└── mediainfo               ← CLI binary  (--dir /opt)

/opt/lib/
├── libmediainfo.so         ← symlink → libmediainfo.so.0.0.0
├── libmediainfo.so.0       ← symlink → libmediainfo.so.0.0.0
└── libmediainfo.so.0.0.0   ← shared library  (--lib-dir /opt/lib)
```

## AWS Lambda layer usage

When used as a Lambda layer the contents land under `/opt`. Package the binaries accordingly:

```sh
# CLI only layer
./mediainfo-downloader.sh --dir ./layer --architecture arm64
cd layer && zip -r ../mediainfo-layer.zip mediainfo

# CLI + library layer
./mediainfo-downloader.sh --dir ./layer --lib-dir ./layer/lib --architecture arm64
cd layer && zip -r ../mediainfo-layer.zip mediainfo lib/
```

The `mediainfo` binary will be available at `/opt/mediainfo` and the library at `/opt/lib/libmediainfo.so` inside the Lambda execution environment.

## Supported architectures

| Value | Resolves to |
|-------|-------------|
| `amd64` | `x86_64` |
| `x86_64` | `x86_64` |
| `arm64` | `arm64` |
| `aarch64` | `arm64` |

## Version format

MediaInfo uses a `YY.MM` versioning scheme (e.g. `26.01` = January 2026).
Latest version is resolved automatically via the [GitHub releases API](https://api.github.com/repos/MediaArea/MediaInfo/releases/latest).

## Testing with Docker Compose

A `docker-compose.yml` is included to test the script across multiple OS and architecture combinations simultaneously.

### Requirements

- Docker with multi-platform support (`linux/amd64` and `linux/arm64`)

### Available test services

| Service | OS | Platform | Version | CLI | Library |
|---|---|---|---|---|---|
| `al2023-arm64-latest-cli` | Amazon Linux 2023 | arm64 | latest | ✓ | |
| `al2023-arm64-latest-cli-lib` | Amazon Linux 2023 | arm64 | latest | ✓ | ✓ |
| `al2023-arm64-v25-10-cli-lib` | Amazon Linux 2023 | arm64 | 25.10 | ✓ | ✓ |
| `al2023-amd64-latest-cli-lib` | Amazon Linux 2023 | amd64 | latest | ✓ | ✓ |
| `al2023-x86-64-v25-10-cli` | Amazon Linux 2023 | amd64 | 25.10 | ✓ | |
| `al2-arm64-latest-cli-lib` | Amazon Linux 2 | arm64 | latest | ✓ | ✓ |
| `al2-arm64-v25-10-cli-lib` | Amazon Linux 2 | arm64 | 25.10 | ✓ | ✓ |
| `err-invalid-arch` | Amazon Linux 2023 | arm64 | — | error case | |
| `err-invalid-version` | Amazon Linux 2023 | arm64 | — | error case | |
| `help` | Amazon Linux 2023 | arm64 | — | `--help` output | |

### Commands

**Run all tests in parallel:**
```sh
docker compose --profile test up
```

**Run all tests and exit when done:**
```sh
docker compose --profile test up --abort-on-container-exit
```

**Run a single service:**
```sh
docker compose --profile test run al2023-arm64-latest-cli-lib
```

**Clean up containers and volumes after testing:**
```sh
docker compose --profile test down
```

All services use the `test` profile so a plain `docker compose up` does nothing by accident.

## Links

- [MediaInfo official site](https://mediaarea.net/en/MediaInfo)
- [MediaInfo Lambda downloads](https://mediaarea.net/en/MediaInfo/Download/Lambda)
- [MediaInfo GitHub](https://github.com/MediaArea/MediaInfo)
