pubflags=--mode debug
dartanalyzer=/usr/lib/dart/bin/dartanalyzer
dartanalyzerflags=--strong
dirs=test web lib

.PHONY: test start build analyze

start:
	find $(dirs) -name '*.dart' | grep -v '#' | entr make build

build: web/*.dart analyze
	pub build $(pubflags)

analyze: 
	$(dartanalyzer) $(dartanalyzerflags) web/main.dart

test:
	find $(dirs) -name '*.dart' | grep -v '#' | entr pub run test test/*.dart

