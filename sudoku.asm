.data


.text
	.global main

	main:


		et_exit: # Program ends here
			mov $1, %eax
			xor %ebx, %ebx
			int $0x80



