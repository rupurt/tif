# Tif

Lightning fast tabular [diffs](./docs/DIFF.md), [patches](./docs/PATCH.md) and
[merges](./docs/MERGE.md) for larger than memory datasets.

## Usage

```shell
tif test/fixtures/people.csv test/fixtures/people_reverse.csv
```

```shell
tif
[-h] [-r <READBUFFER>] [-c <COLBUFFER>] [-m <MAXCOLUMNS>] <PATH1> <PATH1>
```

```shell
tif -h
    -h, --help
            Display this help and exit.

    -r, --readbuffer <READBUFFER>
            Number of bytes to use as a buffer. Default: 65536

    -c, --colbuffer <COLBUFFER>
            Number of bytes to use as a column buffer. Default: 4096

    -m, --maxcolumns <MAXCOLUMNS>
            Maximum number of columns in a record. Default: 512

    <PATH1>
            The base path

    <PATH1>
            The path to compare
```

## How

`tif` produces differences over datasets by generating a [literal](./docs/ARCHITECTURE.md#literal-layer),
[logical](./docs/ARCHITECTURE.md#logical-layer) and [physical](./docs/ARCHITECTURE.md#physical-layer) layer
for the given inputs.

Diffs are produced according to the [Daff tabular diff specification](http://paulfitz.github.io/daff-doc/spec.html).

## Development

This project assumes you have already [installed nix](https://determinate.systems/posts/determinate-nix-installer)

1. Start a Nix devshell

```shell
nix develop -c $SHELL
```

2. Build and run with the zig toolchain

```shell
zig build run -- test/fixtures/people.csv test/fixtures/people_reverse.csv
```

## License

`tif` is released under the [MIT license](./LICENSE)
