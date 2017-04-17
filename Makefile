pubflags=--mode debug
dartanalyzer=/usr/lib/dart/bin/dartanalyzer
dartanalyzerflags=--strong


start:
	find web -name '*.dart' | grep -v '#' | entr make build

build: analyze
	pub build $(pubflags)

analyze: 
	$(dartanalyzer) $(dartanalyzerflags) web/main.dart
