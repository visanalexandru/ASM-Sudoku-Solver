.data
	grid: .space 324 # The grid is a 9*9 = 81 int array, each cell contains a number from 1 to 9

	file_in: .space 4 # The file pointer for the input file 
	file_out: .space 4 # The file pointer for the output file 

	filename_in: .asciz "sudoku.in" # The file name for the input file
	filename_out: .asciz "sudoku.out" # The file name for the output file

	read_mode: .asciz "r" # "read" mode identificator
	write_mode: .asciz "w" # "write" mode identificator

	process_int_format: .asciz "%d " # Format to read/write int 

	# For each line and column (0-8), mark used numbers (1-9). So used_line[line][number] is 1 if the given number
	# appears on the given line, and used_column[column][number] is 1 if the given number appears on the given column
	used_line: .space 90 
	used_column: .space 90

.text
	.global main

	main:
		call read_grid	
		call output_grid

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
		push $filename_in # The path to the file
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

		# Close the input file
		push file_in
		call fclose 
		pop %eax
		
		# Delete the stack frame
		pop %edi # Restore edi
		pop %ebp # Restore ebp
		ret


	output_grid: # This function outputs the solved grid to the file named "sudoku.out"

		# Create the stack frame
		push %ebp # Store ebp
		mov %esp, %ebp
		push %edi # We modify edi so we store it first. 


		push $write_mode # Open the file in the write mode 
		push $filename_out # The path to the file
		call fopen # The file pointer is returned through eax
		pop %ecx
		pop %ecx

		mov %eax, file_out # Set the output file pointer		
		

		lea grid, %edi # Edi now points to the grid
		xor %ecx, %ecx 	# Set ecx to zero, use it as an index in the grid 

		et_output_loop:
			cmp $81, %ecx # Check if ecx has reached the end
			je et_output_loop_end

			
			push %ecx # Store ecx

			pushl (%edi, %ecx, 4) # The value of the cell to output 
			push $process_int_format # Format to write an integer
			push file_out # Pointer to the input file
			call fprintf
			pop %ecx
			pop %ecx
			pop %ecx

			pop %ecx # Restore ecx

			inc %ecx
			jmp et_output_loop

		et_output_loop_end:
		
		# Close the output file
		push file_out 
		call fclose
		pop %eax

		
		# Delete the stack frame
		pop %edi # Restore edi
		pop %ebp # Restore ebp
		ret

	# This function receives an index as a parameter and 
	# returns the corresponding line and column of the index through eax and ecx
	line_and_column:  
		# Create the stack frame
		push %ebp
		mov %esp, %ebp
		

		mov 8(%ebp), %eax # Move the parameter into eax
		xor %edx, %edx # Set edx to zero

		# To get the line, divide the index by 9.
		# The column will be the remainder of the division
		
		mov $9, %ecx # Set ecx to 9, as we will divide by ecx
		div %ecx 

		# Now the line is in eax and column in edx. Move the column number to ecx
		mov %edx, %ecx
		
		# Delete the stack frame
		pop %ebp
		ret
	
	# This function receives an index as a paramter and returns the corresponding square
	# the index cell is situated in through eax.
	square:
		# Create the stack frame
		push %ebp
		mov %esp, %ebp
		
		push $0 # Square row auxiliary variable
		push $0 # Square column auxiliary variable
	

		# Compute the row of the square, divide the index by 27
		mov 8(%ebp), %eax # Move the index into eax
		xor %edx, %edx # Set edx to zero
		mov $27, %ecx # Divide by 27 
		div %ecx
		mov %eax, -4(%ebp) # Set the square row auxiliary variable

		# Compute the column of the square, (index/3)%3 
		mov 8(%ebp), %eax # Move the index into eax
		xor %edx, %edx # Set edx to zero
		mov $3, %ecx # Divide by 3 
		div %ecx
		# Now get the remainder to the division with 3
		xor %edx, %edx
		div %ecx
			
		mov %edx, -8(%ebp) # The remainder is in edx, set the square column auxiliary variable 

		# Now the square number is square_row*3+square_column

		mov -4(%ebp), %eax
		add -4(%ebp), %eax
		add -4(%ebp), %eax
		add -8(%ebp), %eax

		# Delete the stack frame
		pop %ecx # Pop row auxiliary variable
		pop %ecx # Pop column auxiliary variable
		pop %ebp
		ret


