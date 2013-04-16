all:
	coffee -m -c -o ./lib/ ./src/
	cp ./src/*.coffee ./lib

dev:
	coffee -m -o ./lib -cw ./src
