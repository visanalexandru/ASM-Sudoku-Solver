.data
	grid: .space 324 # The grid is a 9*9 = 81 int array, each cell contains a number from 1 to 9

	file_in: .space 4 # The file pointer for the input file 
	file_out: .space 4 # The file pointer for the output file 

	filename_in: .space 4 # A pointer to the file name for the input file
	filename_out: .space 4 # A pointer to the file name for the output file
	usage: .asciz "usage: sudoku (input_file) (output_file) \n" # Error message for an incorrect number of parameters

	read_mode: .asciz "r" # "read" mode identificator
	write_mode: .asciz "w" # "write" mode identificator

	process_int_format: .asciz "%d " # Format to read/write int 

	endline_format: .asciz "\n" # Format to print endline

	# For each line, column and square (0-8), mark used numbers (1-9). So used_line[line][number] is 1 if the given number
	# appears on the given line, used_column[column][number] is 1 if the given number appears on the given column,
	# and used_square[square][number] is 1 if the given number appears on the given square.
	used_line: .space 90 
	used_column: .space 90
	used_square: .space 90

.text
	.global main

	main:
		mov 4(%esp), %eax # Put the number of command line parameters into eax
		cmp $3, %eax # Check if we have 2 command line parameters (2+the path to the executable)
		jne et_incorrect

		et_correct: # The user has provided all the parameters 
			mov 8(%esp), %eax # Move the argument pointer to eax	

			movl 4(%eax), %ecx
			movl %ecx, filename_in # Set filename_in to the first char* in the param list

			movl 8(%eax), %ecx 
			movl %ecx, filename_out # Set filename_out to the second char* in the param list

			call read_grid 

			push $0 # Solve from index 0, meaning from the start of the grid
			call solve
			pop %ecx # Pop the parameter

			call output_grid # Output the grid
			jmp et_exit
		
		et_incorrect: # Incorrect number of parameters
			push $usage
			call printf
			pop %ecx
			jmp et_exit

		et_exit: # Program ends here
			mov $1, %eax
			xor %ebx, %ebx
			int $0x80
	

	read_grid: # This function reads the grid from the file named "sudoku.in"

		# Create the stack frame
		push %ebp # Store ebp
		mov %esp, %ebp
		push %edi # We modify edi so we store it first. 
		push $0 # The line of the current cell to read
		push $0 # The column of the current cell to read
		push $0 # The square of the current cell to read
		push $0 # The current number that has been read


		push $read_mode # Open the file in the read mode 
		push filename_in # The path to the file
		call fopen # The file pointer is returned through eax
		pop %ecx
		pop %ecx

		mov %eax, file_in # Set the input file pointer		
		
		xor %ecx, %ecx 	# Set ecx to zero, use it as an index in the grid 
		et_read_loop:
			cmp $81, %ecx # Check if ecx has reached the end
			je et_read_loop_end

			lea grid, %edi # Edi now points to the grid
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
			
			mov (%edi, %ecx, 4), %eax # Eax now holds the current number
			mov %eax, -20(%ebp) # Set the current number local variable 

			# We now need to update the used_line, used_column and used_square tables accordingly
			# First compute the line and column of the current index
			push %ecx # Store ecx
			call line_and_column
			mov %eax, -8(%ebp) # Set the line local variable
			mov %ecx, -12(%ebp) # Set the column local variable
			pop %ecx # Restore ecx

			# Then compute the square of the current index
			push %ecx # Store ecx
			call square
			mov %eax, -16(%ebp) # Set the square local variable
			pop %ecx # Restore ecx
			
			push %ecx # Store ecx

			# Update used_line[line*10+number]
			et_read_update_line:
				xor %edx, %edx # Set edx to zero
				mov -8(%ebp), %eax # Eax now holds the current line
				mov $10, %ecx # Set ecx to 10 as we will multiply eax by 10
				mul %ecx # eax now holds line*10
				add -20(%ebp), %eax # add the current number to eax, eax now holds line*10+number
				lea used_line, %edi
				movb $1, (%edi, %eax, 1) # Set used_line[line*10+number] to 1 

			# Update used_column[column*10+number]
			et_read_update_column:
				xor %edx, %edx # Set edx to zero
				mov -12(%ebp), %eax # Eax now holds the current column 
				mov $10, %ecx # Set ecx to 10 as we will multiply eax by 10
				mul %ecx # eax now holds column*10
				add -20(%ebp), %eax # add the current number to eax, eax now holds column*10+number
				lea used_column, %edi
				movb $1, (%edi, %eax, 1) # Set used_column[column*10+number] to 1 
			
			# Update used_square[square*10+number]
			et_read_update_square:
				xor %edx, %edx # Set edx to zero
				mov -16(%ebp), %eax # Eax now holds the current square 
				mov $10, %ecx # Set ecx to 10 as we will multiply eax by 10
				mul %ecx # eax now holds square*10
				add -20(%ebp), %eax # add the current number to eax, eax now holds square*10+number
				lea used_square, %edi
				movb $1, (%edi, %eax, 1) # Set used_square[column*10+number] to 1 

			pop %ecx # Restore ecx
			inc %ecx
			jmp et_read_loop

		et_read_loop_end:

		# Close the input file
		push file_in
		call fclose 
		pop %eax
		
		# Delete the stack frame
		pop %ecx # Pop the current number
		pop %ecx # Pop the square of the current cell
		pop %ecx # Pop the column of the current cell
		pop %ecx # Pop the line of the current cell
		pop %edi # Restore edi
		pop %ebp # Restore ebp
		ret


	output_grid: # This function outputs the solved grid to the file named "sudoku.out"

		# Create the stack frame
		push %ebp # Store ebp
		mov %esp, %ebp
		push %edi # We modify edi so we store it first. 


		push $write_mode # Open the file in the write mode 
		push filename_out # The path to the file
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
			push file_out # Pointer to the output file
			call fprintf
			pop %ecx
			pop %ecx
			pop %ecx

			pop %ecx # Restore ecx

			# If we have reached the end of a column, print endline
			push %ecx # Call the line_and column function to get the current column 
			call line_and_column
			mov %ecx, %eax # The current column is in ecx, move it into eax		
			pop %ecx # Restore ecx

			cmp $8, %eax # Check if we have reached the end of a column 
			jne et_output_next
				
			# We have reached the end of a column, print endline
			push %ecx  # Store ecx
			push $endline_format # Format to print endline
			push file_out # Pointer to the output file
			call fprintf
			pop %ecx
			pop %ecx
			pop %ecx # Restore ecx

			et_output_next:	
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
	
	# This function tries to recursively solve the grid. It returns 1 through eax if it has found
	# a solution to the puzzle, or 0 if a solution does not exist. If a solution exists, the grid
	# will be modified accordingly. The only parameter is the index of the current cell to modify.
	solve:
		# Create the stack frame
		push %ebp
		mov %esp, %ebp
		push %edi # We modify edi, so we store it first
		push %ebx # We modify ebx, so we store it first
		push $0 # The line of the current cell  
		push $0 # The column of the current cell 
		push $0 # The square of the current cell 
		push $0 # A pointer to access used_line[line][number]
		push $0 # A pointer to access used_column[column][number]
		push $0 # A pointer to access used_square[square][number]
		
		# Check if we have finished solving the grid
		cmp $81, 8(%ebp)
		jne et_not_finished
		
		et_finished: # We have finished solving the puzzle, return 1 through eax
			mov $1, %eax
			jmp et_solve_return
			
		et_not_finished:
			mov 8(%ebp), %edx # Move the current index to edx
			lea grid, %edi
			cmp $0, (%edi, %edx, 4) # Check if the current cell is fixed
			je et_not_fixed

			et_fixed: # The current cell is fixed, just skip the current cell, solve for index+1
				inc %edx # Increment the current index 

				push %edx
				call solve # Solve for index+1
				pop %edx

				jmp et_solve_return

			et_not_fixed: # The current cell is not fixed, we need to try all possible numbers  
				
				# We first get the line and column of the current cell
				push 8(%ebp) # Push the index of the current cell
				call line_and_column
				pop %edx
				
				mov %eax, -12(%ebp)  # Set the line local variable
				mov %ecx, -16(%ebp)  # Set the column local variable


				# We then get the square of the current cell
				push 8(%ebp) # Push the index of the current cell
				call square
				pop %edx

				mov %eax, -20(%ebp) # Set the square local variable

				mov $1,%ecx 
				et_choice_loop: # Loop through numbers from 1 to 9
					cmp $10, %ecx # Check if ecx has reached the end
					je et_choice_loop_end
					
					# Check if the current number already exists on this line
					# So we need to check used_line[line*10+number] 
					et_check_line:
						mov -12(%ebp), %eax # Move the current line index into eax
						xor %edx, %edx # Set edx to zero 
						mov $10, %ebx # Set ebx to 10 as we will multipy the line index by 10 
						mul %ebx
						add %ecx, %eax # eax now holds line*10+number

						lea used_line, %edi
						lea (%edi, %eax, 1), %eax # Load the pointer to used_line[line][number] to eax 
						mov %eax, -24(%ebp) # Update the pointer to used_line[line][number]
						cmpb $1, (%eax) # If the number already exists on the current line, we cannot add it
						je et_choice_invalid

					# Check if the current number already exists on this column 
					# So we need to check used_column[column*10+number] 
					et_check_column:
						mov -16(%ebp), %eax # Move the current column index into eax
						xor %edx, %edx # Set edx to zero 
						mov $10, %ebx # Set ebx to 10 as we will multipy the column index by 10 
						mul %ebx
						add %ecx, %eax # eax now holds column*10+number

						lea used_column, %edi
						lea (%edi, %eax, 1), %eax # Load the pointer to used_column[column][number] to eax 
						mov %eax, -28(%ebp) # Update the pointer to used_column[column][number]
						cmpb $1, (%eax) # If the number already exists on the current column, we cannot add it
						je et_choice_invalid
					
					# Check if the current number already exists in this square
					# So we need to check used_square[square*10+number]
					et_check_square:
						mov -20(%ebp), %eax # Move the current square index into eax
						xor %edx, %edx # Set edx to zero
						mov $10, %ebx # Set ebx to 10 as we will multiply the square index by 10
						mul %ebx
						add %ecx, %eax # eax now holds square*10+number

						lea used_square, %edi
						lea (%edi, %eax, 1), %eax # Load the pointer to used_square[square][number] to eax 
						mov %eax, -32(%ebp) # Update the pointer to used_square[column][number]
						cmpb $1, (%eax) # If the number already exists on the current square, we cannot add it
						je et_choice_invalid

					# We found a valid choice, update used_line, used_column, used_sqare and the grid
					et_choice_valid:	
						# First update the used_line table, using the pointer to used_line[line][number]
						mov -24(%ebp), %eax
						movb $1, (%eax) # Set used_line[line][number] to 1

						# Then update the used_column table, using the pointer to used_column[column][number]
						mov -28(%ebp), %eax
						movb $1, (%eax) # Set used_column[column][number] to 1

						# Then update the used_square table, using the pointer to used_square[square][number]
						mov -32(%ebp), %eax
						movb $1, (%eax) # Set used_square[column][number] to 1
						
						# Then update the grid cell
						lea grid, %edi
						mov 8(%ebp), %eax # Move the index of the current cell to eax
						mov %ecx, (%edi, %eax, 4) # Update the current cell with the current choice
						
						# Now call solve for index+1
						mov 8(%ebp), %eax
						inc %eax # Eax now holds index+1

						push %ecx # Store ecx before the call
						push %eax # Push index+1 as a parameter
						call solve # eax now holds 1 if we found a solution
						pop %ecx # Pop the parameter
						pop %ecx # Restore ecx
					
						# If eax holds 1, we have found a solution to the puzzle, just return
						cmp $1, %eax
						je et_solve_return

						# Else we need to restore the previous state
						# First restore the used_line table 
						mov -24(%ebp), %eax
						movb $0, (%eax) # Set used_line[line][number] to 0 

						# Then restore the used_column table 
						mov -28(%ebp), %eax
						movb $0, (%eax) # Set used_column[column][number] to 0 

						# Then restore the used_square table 
						mov -32(%ebp), %eax
						movb $0, (%eax) # Set used_square[column][number] to 0 

						# Then restore the grid cell
						lea grid, %edi
						mov 8(%ebp), %eax # Move the index of the current cell to eax
						movl $0, (%edi, %eax, 4) # Set the current cell back to 0 

						jmp et_choice_next # Jump to the next number to try

					et_choice_invalid: # The current number is not valid, try the next one
						jmp et_choice_next
					
					et_choice_next:
					inc %ecx
					jmp et_choice_loop
				et_choice_loop_end:

				# If we did not found any solution, return 0 through eax
				xor %eax, %eax # Set eax to zero
				jmp et_solve_return

		et_solve_return:
			# Delete the stack frame
			pop %ecx # Pop the pointer to used_square[square][number] 
			pop %ecx # Pop the pointer to used_column[column][number] 
			pop %ecx # Pop the pointer to used_line[line][number] 
			pop %ecx # Pop the square
			pop %ecx # Pop the column 
			pop %ecx # Pop the line 
			pop %ebx # Restore ebx
			pop %edi # Restore edi
			pop %ebp
			ret

