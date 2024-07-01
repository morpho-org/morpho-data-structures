help:
	@echo "usage: two possible munging, either simple DLL of DLL with FIFO"

munged-simple: $(wildcard ../src/*.sol) applyHarnessSimple.patch
	@rm -rf munged-simple
	@cp -r ../src munged-simple
	@patch -p0 -d munged-simple < applyHarnessSimple.patch

record-simple:
	diff -ruN ../src munged-simple | sed 's+\.\./src/++g' | sed 's+munged-simple/++g' > applyHarnessSimple.patch

munged-fifo: $(wildcard ../src/*.sol) applyHarnessFifo.patch
	@rm -rf munged-fifo
	@cp -r ../src munged-fifo
	@patch -p0 -d munged-fifo < applyHarnessFifo.patch

record-fifo:
	diff -ruN ../src munged-fifo | sed 's+\.\./src/++g' | sed 's+munged-fifo/++g' > applyHarnessFifo.patch

clean:
	rm -rf munged-simple munged-fifo

.PHONY: help clean # do not add munged here, as it is useful to protect munged edits
