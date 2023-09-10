# Tif

Lightning fast tabular diffs, patches and merges for large datasets.

## Usage

```shell
tif test/fixtures/people.csv test/fixtures/people_reverse.csv
```

```shell
tif
[-h] <FILE1> <FILE2>
```

```shell
tif -h
-h, --help
            Display this help and exit.

    <FILE1>
            The base file

    <FILE2>
            The file to compare
```

## How

`tif` produces differences over datasets by generating a literal, logical and physical structure
for the given inputs.

Diffs are produced according to the [Daff tabular diff specification](http://paulfitz.github.io/daff-doc/spec.html).

## Development

This project assumes you have already [installed nix](https://determinate.systems/posts/determinate-nix-installer)

1. Start a Nix devshell

```shell
nix develop -c $SHELL
```

2. Build and run with the zig compiler

```shell
zig build run -- test/fixtures/people.csv test/fixtures/people_reverse.csv
```

## License

`tif` is released under the [MIT license](./LICENSE)
