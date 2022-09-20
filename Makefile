.PHONY: test install

export FOUNDRY_TEST=test-foundry

install:
	@git submodule update --init --recursive
	@yarn

gas-report:
	@echo Run all tests
	@forge test -vvv --gas-report

test:
	@echo Run all tests
	@forge test -vvv

contract-% c-%:
	@echo Run tests for contract $*
	@forge test -vvv --match-contract $*

single-% s-%:
	@echo Run single test: $*
	@forge test -vvv --match-test $*
