pubflags=--mode debug
dartanalyzer=/usr/lib/dart/bin/dartanalyzer
dartanalyzerflags=--strong

.PHONY: test start build analyze

start:
	find web -name '*.dart' | grep -v '#' | entr make build

build: web/*.dart analyze
	pub build $(pubflags)

analyze: 
	$(dartanalyzer) $(dartanalyzerflags) web/main.dart

test:
	find . -name '*.dart' | grep -v '#' | entr pub run test test/*.dart

