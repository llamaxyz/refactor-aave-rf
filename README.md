# Refactor AAVE Reserve Factor

We will independently deploy the `Refactor` contract and propose an AIP that will call its execute function. This repo contains the contract, tests and deployment script to ensure the integrity of proposal execution. The actual governance proposal and testing of the voting process will be in a fork of [AIP](https://github.com/aave/aip).

## Setup

- Rename `.env.example` to `.env`. Add a valid URL for an Ethereum JSON-RPC client for the `FORK_URL` variable
- Follow the [foundry installation instructions](https://github.com/gakonst/foundry#installation)

## Tests

```
$ make test # run tests without traces
$ make trace # run tests with traces
```