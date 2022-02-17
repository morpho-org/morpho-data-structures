
.PHONY: test
test: node_modules
	@echo Run all tests
	@forge test -vvv -c test-foundry

contract-% c-%: node_modules
	@echo Run tests for contract $*
	@forge test -vvv -c test-foundry --match-contract $*

single-% s-%: node_modules
	@echo Run single test: $*
	@forge test -vvvvv -c test-foundry --match-test $*

node_modules:
	@yarn