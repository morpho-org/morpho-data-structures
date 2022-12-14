-include .env.local
.EXPORT_ALL_VARIABLES:
MAKEFLAGS += --no-print-directory

contracts:
	FOUNDRY_TEST=/dev/null forge build --sizes --force

test:
	@echo Running tests with seed \"${FOUNDRY_FUZZ_SEED}\",\
		match contract patterns \"\(${FOUNDRY_MATCH_CONTRACT}\)!${FOUNDRY_NO_MATCH_CONTRACT}\",\
		match test patterns \"\(${FOUNDRY_MATCH_TEST}\)!${FOUNDRY_NO_MATCH_TEST}\"

	forge test -vvv | tee trace.ansi

test-%:
	@FOUNDRY_MATCH_TEST=$* make test

contract-% c-%:
	@FOUNDRY_MATCH_CONTRACT=$* make test

coverage:
	@echo Create lcov coverage report
	forge coverage --report lcov
	lcov --remove lcov.info -o lcov.info "test/*"

lcov-html:
	@echo Transforming the lcov coverage report into html
	genhtml lcov.info -o coverage


.PHONY: test coverage contracts
