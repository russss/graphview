all:
	coffee -c -o ./lib/ ./src/

dev:
	coffee -o ./lib -cw ./src
