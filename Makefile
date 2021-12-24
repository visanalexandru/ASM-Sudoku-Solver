run: sudoku
	./sudoku

sudoku: sudoku.o
	gcc -m32 sudoku.o -o sudoku

sudoku.o: sudoku.asm
	as --32 -g sudoku.asm -o sudoku.o
