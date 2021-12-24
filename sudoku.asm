.data
	grid: .space 324 # The grid is a 9*9 = 81 int array, each cell contains a number from 1 to 9

	file_in: .space 4 # The file pointer for the input file 
	file_out: .space 4 # The file pointer for the output file 

	filename_in: .asciz "sudoku.in" # The file name for the input file
	filename_out: .asciz "sudoku.out" # The file name for the output file

	read_mode: .asciz "r" # "read" mode identificator
	write_mode: .asciz "w" # "write" mode identificator

	process_int_format: .asciz "%d " # Format to read/write int 


.text
	.global main

	main:
		call read_grid	

		et_exit: # Program ends here
			mov $1, %eax
			xor %ebx, %ebx
			int $0x80
	

	read_grid: # This function reads the grid from the file named "sudoku.in"

		# Create the stack frame
		push %ebp # Store ebp
		mov %esp, %ebp
		push %edi # We modify edi so we store it first. 


		push $read_mode # Open the file in the read mode 
		push $filename_in
		call fopen # The file pointer is returned through eax
		pop %ecx
		pop %ecx

		mov %eax, file_in # Set the input file pointer		
		

		lea grid, %edi # Edi now points to the grid
		xor %ecx, %ecx 	# Set ecx to zero, use it as an index in the grid 

		et_read_loop:
			cmp $81, %ecx # Check if ecx has reached the end
			je et_read_loop_end

			lea (%edi, %ecx, 4), %eax # Load the pointer to the element to read in eax
			
			push %ecx # Store ecx

			push %eax # The address of the cell to read
			push $process_int_format # Format to read an integer
			push file_in # Pointer to the input file
			call fscanf
			pop %ecx
			pop %ecx
			pop %ecx
			

			pop %ecx # Restore ecx

			inc %ecx
			jmp et_read_loop

		et_read_loop_end:
		
		# Delete the stack frame
		pop %edi # Restore edi
		pop %ebp # Restore ebp
		ret



