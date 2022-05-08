# Refactor AAVE Reserve Factor

We will independently deploy the `ProposalPayload` contract and propose an AIP that will call its execute function. This repo contains the contract, tests and deployment script to ensure the integrity of proposal execution. The actual governance proposal and testing of the voting process will be in a fork of [AIP](https://github.com/aave/aip).

## Setup

- Follow the [foundry installation instructions](https://github.com/gakonst/foundry#installation)

```
$ git clone https://github.com/llama-community/refactor-aave-rf.git
$ cd refactor-aave-rf
$ git submodule update --init --recursive
```

## Tests

```
$ make test
```
