pubflags=--mode debug

start:
	find web -name '*.dart' | grep -v '#' | entr pub build $(pubflags)
