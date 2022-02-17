# Forge Template ⚒️

A template that pulled features and utilities from many other implementations to speed up your development process with Forge.

## Foundry Installation

First run the command below to get foundryup, the Foundry toolchain installer:

```
curl -L https://foundry.paradigm.xyz | bash
```

Then, in a new terminal session or after reloading your PATH, run it to get the latest forge and cast binaries:

```
foundryup
```
Advanced ways to use `foundryup`, and other documentation, can be found in the [foundryup package](./foundryup/README.md)

## Getting Started

```
mkdir new-project
cd new-project
forge init --template https://github.com/nicolasgarcia214/forge-template
git submodule update --init --recursive  ## initialize submodule dependencies
yarn install ## install development dependencies
forge build
forge test
```

## Features

### Testing Utilities

Includes a `Utilities.sol` contract with common testing methods (like creating users with an initial balance), as well as various other utility contracts.

### Preinstalled dependencies

`ds-test` for testing, `forge-std` for better cheatcode UX, and `openzeppelin-contracts` for contract implementations. 

### Install dependencies

Use `forge install [OPTIONS] [DEPENDENCIES]` _(installs one or more dependencies as git submodules)_

### Update dependencies

You can update a specific dependency to the latest commit on the version you have specified using `forge update [OPTIONS] [DEPENDENCIES]`

### Linting

Pre-configured `solhint` and `prettier-plugin-solidity`. Can be run by

```
yarn lint
yarn format
```

### CI with Github Actions

Automatically run linting and tests on pull requests.

### Default Configuration

Including `.gitignore`, `.vscode`, `remappings.txt`, `foundry.toml` and `.prettierignore`

### Project Configuration
Forge can be configured using a configuration file called `foundry.toml`, which is placed in the root of your project.
For more information, visit this link: https://onbjerg.github.io/foundry-book/reference/config.html

### Acknowledgement
> This template is based on the following repo: https://github.com/FrankieIsLost/forge-template.
