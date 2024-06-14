# bash-scripts

This repository contains various `bash` scripts

## Pre-commit Hooks

This repo uses [pre-commit hooks](https://pre-commit.com/) for linting and formatting the source code before the commit.

### `Setup`

- Install `pre-commit` using instructions [here](https://pre-commit.com/#installation). Run this command for MacOS:

```sh
brew install pre-commit
```

- Install the hooks (should be done once per repository):

```sh
pre-commit install
```

### `Usage`

The hooks will run automatically before every commit, fixing the files according to hooks configured in `.pre-commit-config.yaml`.  
If you want to run the checks manually without committing, use the command:

```sh
pre-commit run -a
```

## Authors

- [@langburd](https://www.github.com/langburd)
