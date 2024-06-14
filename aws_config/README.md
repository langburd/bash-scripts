# set_aws_config.sh

This folder contains a shell script, `set_aws_config.sh`, that helps to set up your AWS CLI configuration.

## Prerequisites

- `AWS CLI` installed. If not, the script will prompt you to install it. You can follow the instructions at [https://aws.amazon.com/cli](https://aws.amazon.com/cli).
- `jq` installed. If not, the script will prompt you to install it. You can follow the instructions at [https://jqlang.github.io/jq](https://jqlang.github.io/jq).

## Description

`set_aws_config.sh` is a shell script used to retrieve the AWS CLI configuration for all available AWS accounts in AWS organization.

## Usage

1. Run the script using the command `./set_aws_config.sh`.
2. The script will check if all prerequisites are installed. It will exit and prompt you to install the missing prerequisite (See [Prerequisites](#prerequisites)) in it finds one.
3. The script will ask you for the AWS Management Account ID. If you want to use the predefined ID (`123456789101`), just press Enter.
4. The script will ask for the AWS SSO start URL. If you want to use the predefined URL (`https://company.awsapps.com/start`), just press Enter.
5. The script will then generate a new AWS configuration and save it to `~/.aws/config`.
6. If a previous configuration file exists, the script will ask if you want to overwrite it. The previous configuration will be backed up to `~/.aws/config.bak`.
7. The script will then log in to AWS SSO and list all the organization accounts in AWS Organizations.
8. For each account, the script will add a new profile to the AWS configuration.

## Note

This script is part of the [langburd/bash-scripts](https://github.com/langburd/bash-scripts) repository.
