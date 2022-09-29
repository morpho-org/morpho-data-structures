help:
	@echo "usage: two possible munging, either simple DLL of DLL with FIFO"

munged-simple: $(wildcard ../contracts/*.sol) applyHarnessSimple.patch
	@rm -rf munged-simple
	@cp -r ../contracts munged-simple
	@patch -p0 -d munged-simple < applyHarnessSimple.patch

munged-fifo: $(wildcard ../contracts/*.sol) applyHarnessFIFO.patch
	@rm -rf munged-fifo
	@cp -r ../contracts munged-fifo
	@patch -p0 -d munged-fifo < applyHarnessFIFO.patch

record:
	diff -ruN ../contracts munged-simple | sed 's+\.\./contracts/++g' | sed 's+munged-simple/++g' > applyHarnessSimple.patch
	diff -ruN ../contracts munged-fifo | sed 's+\.\./contracts/++g' | sed 's+munged-fifo/++g' > applyHarnessFIFO.patch

clean:
	rm -rf munged-simple munged-fifo

.PHONY: help record clean # do not add munged here, it is used to protect munged edits
