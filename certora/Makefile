help:
	@echo "usage: two possible munging, either simple DLL of DLL with FIFO"

munged-simple: $(wildcard ../src/*.sol) applyHarnessSimple.patch
	@rm -rf munged-simple
	@cp -r ../src munged-simple
	@patch -p0 -d munged-simple < applyHarnessSimple.patch

record-simple:
	diff -ruN ../src munged-simple | sed -E 's,\.\./src/|munged-simple/,,g' | sed -E 's,((\-\-\-|\+\+\+) [^[:space:]]*).*,\1,' > applyHarnessSimple.patch

munged-fifo: $(wildcard ../src/*.sol) applyHarnessFifo.patch
	@rm -rf munged-fifo
	@cp -r ../src munged-fifo
	@patch -p0 -d munged-fifo < applyHarnessFifo.patch

record-fifo:
	diff -ruN ../src munged-fifo | sed -E 's,\.\./src/|munged-fifo/,,g' | sed -E 's,((\-\-\-|\+\+\+) [^[:space:]]*).*,\1,' > applyHarnessFifo.patch

clean:
	rm -rf munged-simple munged-fifo

.PHONY: help clean record-simple record-fifo # do not add munged folders here, as it is useful to protect munged edits
