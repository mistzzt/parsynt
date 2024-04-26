all:
	dune build src/Lib.a --profile release
	dune build bin/Parsynt.exe --profile release