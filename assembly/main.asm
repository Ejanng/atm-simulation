.data

# ===========================
# ========= Message =========
# ===========================
displayWelcomeMsg:	.asciiz		"Welcome to ATM-Simulation\n1. Create Account\n2. Login\n3. Exit\n"
displayMenu:		.asciiz		"1. Deposit\n2. Withdraw\n3. Transfer\n.4. Check Info\n5. View Transaction History\n6. Logout"
displayUserInputMsg:	.asciiz		"Enter your choice: "
displayInvalid:		.asciiz		"Invalid choice!\n\n"
newline:		.asciiz		"\n"
space:			.asciiz		" "

# ====== Create Account =====
createUserMsg: 		.asciiz		"Enter username: "
createPassMsg:		.asciiz		"Enter password: "
createSuccessMsg:	.asciiz		"Account create successfully!"
createFailMsg:		.asciiz		"Creation failed!"
error_write_msg:	.asciiz 	"Failed to write to file.\n"
error_open_msg: 	.asciiz 	"Error opening file.\n"

# ========== Login ===========
login_prompt:   	.asciiz 	"Login to your account\n"
loginUsermMsg:		.asciiz		"Username: "
loginPassMsg:		.asciiz		"Password: "
error_open:     	.asciiz 	"Error opening file.\n"
success_msg:    	.asciiz 	"Login successful!\n"
user_id_msg:    	.asciiz 	"User ID: "
banknote_msg:   	.asciiz 	"Banknote: "

# ========= Deposit ==========
depositAmountMsg:	.asciiz		"Enter amount you want to deposit: "
invalidDepositMsg:	.asciiz		"Invalid deposit amount."
depositSuccessMsg1:	.asciiz		"User: "
depositSuccessMsg2: 	.asciiz		"deposit a total amount of "
depositSuccessMsg:	.asciiz		"Deposit successful! New Balance: "

# ========= Withdraw =========
withdrawAmountMsg:	.asciiz		"Enter amount you want to withdraw: "
invalidWithdrewMsg:	.asciiz		"Invalid withdrawal amount."		# if user input less than 0
invalidWithdrawBalance: .asciiz		"Insufficient balance."
withdrawSuccessMsg1:	.asciiz		"User: "
withdrawSuccessMsg2: 	.asciiz		"withdrew a total amount of "
withdrawSuccessMsg:	.asciiz		"Withdraw successful! New Balance: "

# ========= Transfer =========
transferUserIdMsg:	.asciiz		"Enter the receiver's User ID: "
transferAmoundMsg: 	.asciiz		"Enter the amount to transfer: "
invalidTransferBalance:	.asciiz		"Invalid transfer amount."		# if user input less than 0
invalidSenderMsg:	.asciiz		"Sender not found."
invalidReceiverMsg:	.asciiz		"Receiver not found."
insufficientTransfer:	.asciiz		"Insufficient balance for transfer."
tranferSuccessMsg1:	.asciiz		"User: "
tranferSuccessMsg2: 	.asciiz		"transferred "
tranferSuccessMsg3:	.asciiz		"to a User: "
tranferSuccessMsg:	.asciiz		"Transfer successful! Your new  balance: "

# ======= Check Info =========
showUserIdMsg:		.asciiz		"User ID: "
showBanknoteMsg:	.asciiz		"Banknote: "

# ===== View Transaction =====

# ========== Buffer ==========
username:		.space		50
password:		.space		50
buffer:			.space		100


# ============================
# ========= Variables ========
# ============================
MAX_USER:		.word		50
id:			.space		12
seed:			.word 		0

loginUsername:  	.space 		50
loginPassword:  	.space 		50
storedUsername: 	.space 		50
storedPassword: 	.space 		50


# ============================
# ==== Global  Variables =====
# ============================
userId:         	.word 		0
banknote:       	.word 		0
userIdPtr:      	.word 		0
banknotePtr:    	.word 		0


# ============================
# ========= Files ============
# ============================
users_txt:		.asciiz		"C:/Users/earlj/OneDrive/Documents/c/atm-simulation/assembly/users.txt"
transaction_txt:	.asciiz		"C:/Users/earlj/OneDrive/Documents/c/atm-simulation/assembly/transaction.txt"
errmsg:			.asciiz		"Error opening file"

# ============================
# ========= Debug ============
# ============================
sampleMsg:  		.asciiz 	"ijb juhgyiitfg87tf\n"

.globl main
.text
main:
	# displayWelcomeMessage();
	li	$v0, 4
	la	$a0, displayWelcomeMsg
	syscall
	
home_case_start:
	li	$v0, 4
	la	$a0, displayUserInputMsg
	syscall
	li	$v0, 5
	syscall
	move	$t0, $v0
	li	$t1, 1
	beq	$t0, $t1, home_case_1
	li	$t2, 2
	beq	$t0, $t2, home_case_2
	li	$t3, 3
	beq	$t0, $t3, home_case_3
	li	$t4, 4
	beq	$t0, $t4, debug
	 
home_default:
	li	$v0, 4
	la	$a0, displayInvalid
	syscall
	j	home_case_start
home_case_1:
	jal 	createAccount
home_case_2:
	jal	loginAccount
home_case_3:	

debug:
	# Open file
    	li   $v0, 13         # syscall: open file
    	la   $a0, users_txt  # file name
    	li   $a1, 9          # flags: write + append
    	syscall
    	move $s0, $v0        # file descriptor

    	# Check if open failed
    	bltz $s0, file_open_failed

    	# Write to file
    	li   $v0, 15         # syscall: write to file
    	move $a0, $s0        # file descriptor
    	la   $a1, sampleMsg  # string to write
    	li   $a2, 24         # number of bytes
    	syscall

    	bltz $v0, write_failed

    	# Close file
    	li   $v0, 16
    	move $a0, $s0
    	syscall

    	# Exit
    	li $v0, 10
    	syscall

file_open_failed:
    	li $v0, 4
    	la $a0, createFailMsg
    	syscall
    	li $v0, 10
    	syscall
	
write_failed:
    	li $v0, 4
    	la $a0, createFailMsg
    	syscall
    	li $v0, 10
    	syscall

createAccount:
	# Prologue
    	addi $sp, $sp, -16
    	sw $ra, 0($sp)
    	sw $s0, 4($sp)   # File descriptor
    	sw $s1, 8($sp)   # User ID
    	sw $s2, 12($sp)  # Banknote value (10000)
    	
    	# Initialize banknote value
    	li $s2, 10000

    	# Open file (append mode)
    	li $v0, 13       # syscall for open file
    	la $a0, users_txt
    	li $a1, 9         # Append and write flags (O_WRONLY|O_APPEND|O_CREAT)
    	li $a2, 0         # mode is ignored
    	syscall
    	move $s0, $v0     # Save file descriptor
    
    	bltz $s0, create_open_error  # if file descriptor < 0, error

    	# Prompt for username
    	li $v0, 4
    	la $a0, createUserMsg
    	syscall
    
    	# Read username
    	li $v0, 8
    	la $a0, username
    	li $a1, 50
    	syscall
   	 
   	# Remove newline from username
    	la $a0, username
    	jal remove_newline
	
    	# Prompt for password
    	li $v0, 4
    	la $a0, createPassMsg
    	syscall
    	
    	# Read password
    	li $v0, 8
    	la $a0, password
    	li $a1, 50
    	syscall
    
    	# Remove newline from password
    	la $a0, password
    	jal remove_newline
	
    
    	# Generate random user ID (0-99999)
    	li $v0, 30        # syscall for system time
    	syscall
    	move $a1, $a0     # seed = time
    	li $a0, 0         # ID = 0
    	li $v0, 40        # syscall for set seed
    	syscall
    
    	li $a0, 0         # ID = 0
    	li $a1, 100000    # upper bound
    	li $v0, 42        # syscall for random int range
    	syscall
    	move $s1, $a0     # save user ID

    	# Format the output string: "userId username password banknote\n"
    	la $a0, buffer
    	move $a1, $s1     # user ID
    	la $a2, username
    	la $a3, password
    	jal format_record

    	# Write to file
    	li $v0, 15        # syscall for write to file
    	move $a0, $s0     # file descriptor
    	la $a1, buffer    # buffer to write
    	li $a2, 100       # length to write (max)
    	syscall
    	
    	bltz $v0, write_error  # if bytes written < 0, error
	
    	# Success message
    	li $v0, 4
    	la $a0, createSuccessMsg
    	syscall
    
    	li $v0, 4
    	la $a0, username
    	syscall
    
    	li $v0, 4
    	la $a0, newline
    	syscall
    
    	j close_file

create_open_error:
    	li $v0, 4
    	la $a0, error_open_msg
    	syscall
    	j createAccount_end

write_error:
    	li $v0, 4
    	la $a0, error_write_msg
    	syscall

close_file:
    	# Close file
    	li $v0, 16        # syscall for close file
    	move $a0, $s0
    	syscall
    	
    	j main

createAccount_end:
    	# Epilogue
    	lw $ra, 0($sp)
    	lw $s0, 4($sp)
    	lw $s1, 8($sp)
    	lw $s2, 12($sp)
    	addi $sp, $sp, 16
    	jr $ra

# Helper function to remove newline from string
remove_newline:
    	li $t0, 0
remove_loop:
    	lb $t1, ($a0)
    	beq $t1, '\n', replace_null
    	beqz $t1, remove_done
    	addi $a0, $a0, 1
    	j remove_loop
replace_null:
    	sb $zero, ($a0)
remove_done:
    	jr $ra

# Format record: userId username password banknote\n
# Arguments:
#   $a0 - buffer address
#   $a1 - user ID
#   $a2 - username address
#   $a3 - password address
format_record:
    	# Prologue
    	addi $sp, $sp, -4
    	sw $ra, 0($sp)
    
    	move $t0, $a0     # buffer pointer
    
    	# Convert user ID to string and write to buffer
    	move $a0, $a1
    	move $a1, $t0
    	jal int_to_string
    	move $t0, $v0     # update buffer pointer
    
    	# Add space
    	li $t1, ' '
    	sb $t1, ($t0)
    	addi $t0, $t0, 1
    
    	# Copy username
    	move $a0, $t0
    	move $a1, $a2
    	jal strcpy
    	move $t0, $v0
    
    	# Add space
    	li $t1, ' '
    	sb $t1, ($t0)
    	addi $t0, $t0, 1
    
    	# Copy password
    	move $a0, $t0
    	move $a1, $a3
    	jal strcpy
    	move $t0, $v0
    
    	# Add space
    	li $t1, ' '
    	sb $t1, ($t0)
    	addi $t0, $t0, 1
    
    	# Add banknote value (10000)
    	li $a0, 10000
    	move $a1, $t0
    	jal int_to_string
    	move $t0, $v0
    	
    	# Add newline
    	li $t1, '\n'
    	sb $t1, ($t0)
    	addi $t0, $t0, 1
    
    	# Null terminate
    	sb $zero, ($t0)
    	
    	# Epilogue
    	lw $ra, 0($sp)
    	addi $sp, $sp, 4
    	jr $ra
	
# Helper function: integer to string
# Arguments:
#   $a0 - integer value
#   $a1 - buffer address
# Returns:
#   $v0 - pointer to end of string
int_to_string:
    	li $t0, 10
    	li $t1, 0
    	move $t2, $a1
    
    	# Handle zero case
    	beqz $a0, zero_case
    
    	# Count digits
    	move $t3, $a0
count_loop:
    	div $t3, $t0
    	mflo $t3
    	addi $t1, $t1, 1
    	bnez $t3, count_loop
    
    	# Null terminate
    	add $t2, $t2, $t1
    	sb $zero, ($t2)
	addi $t2, $t2, -1
    
    	# Convert digits
   	move $t3, $a0
convert_loop:
    	div $t3, $t0
    	mfhi $t4
    	mflo $t3
    	addi $t4, $t4, '0'
    	sb $t4, ($t2)
    	addi $t2, $t2, -1
    	bnez $t3, convert_loop
    
    	move $v0, $a1
    	add $v0, $v0, $t1
    	jr $ra
    
zero_case:
    	li $t4, '0'
    	sb $t4, ($t2)
    	sb $zero, 1($t2)
    	addi $v0, $t2, 1
    	jr $ra

# Helper function: string copy
# Arguments:
#   $a0 - destination address
#   $a1 - source address
# Returns:
#   $v0 - pointer to end of destination string
strcpy:
    	move $t0, $a0
   	move $t1, $a1
strcpy_loop:
    	lb $t2, ($t1)
    	beqz $t2, strcpy_done
    	sb $t2, ($t0)
    	addi $t0, $t0, 1
    	addi $t1, $t1, 1
    	j strcpy_loop
strcpy_done:
    	sb $zero, ($t0)
    	move $v0, $t0
    	jr $ra
	
loginAccount:
	# Prologue
    	addi $sp, $sp, -24
    	sw $ra, 0($sp)
    	sw $s0, 4($sp)   # File descriptor
    	sw $s1, 8($sp)   # found flag
    	sw $s2, 12($sp)  # temp storage
    	sw $s3, 16($sp)  # userIdPtr
    	sw $s4, 20($sp)  # banknotePtr

    	# Initialize pointers
    	la $s3, userId
    	la $s4, banknote
    	sw $s3, userIdPtr
    	sw $s4, banknotePtr

    	# Print login prompt
    	li $v0, 4
    	la $a0, login_prompt
    	syscall

    	# Get username
    	li $v0, 4
    	la $a0, loginUsermMsg
    	syscall
    	li $v0, 8
    	la $a0, loginUsername
    	li $a1, 50
    	syscall

    	# Get password
    	li $v0, 4
    	la $a0, loginPassMsg
    	syscall
    	li $v0, 8
    	la $a0, loginPassword
    	li $a1, 50
    	syscall

    	# Remove newlines from inputs
    	la $a0, loginUsername
    	jal remove_newline
    	la $a0, loginPassword
    	jal remove_newline

    	# Open file
   	li $v0, 13
    	la $a0, users_txt
    	li $a1, 0        # Read mode
    	syscall
    	move $s0, $v0    # Save file descriptor
    	bltz $s0, login_open_error

    	li $s1, 0        # found = 0

read_loop:
    	# Read user ID
    	li $v0, 14
    	move $a0, $s0
    	la $a1, userId
    	li $a2, 4
    	syscall
    	blez $v0, end_loop  # EOF or error
	
    	# Read username
    	li $v0, 14
    	move $a0, $s0
    	la $a1, storedUsername
    	li $a2, 50
    	syscall
    	blez $v0, end_loop
	
    	# Read password
    	li $v0, 14
    	move $a0, $s0
    	la $a1, storedPassword
    	li $a2, 50
    	syscall
    	blez $v0, end_loop	

    	# Read banknote
    	li $v0, 14
    	move $a0, $s0
    	la $a1, banknote
    	li $a2, 4
    	syscall
    	blez $v0, end_loop

    	# Compare strings
    	la $a0, loginUsername
    	la $a1, storedUsername
    	jal strcmp
    	bnez $v0, read_loop  # Username mismatch
		
    	la $a0, loginPassword
    	la $a1, storedPassword
    	jal strcmp
    	bnez $v0, read_loop  # Password mismatch

    	# Match found
    	li $s1, 1
    	j end_loop

login_open_error:
    	li $v0, 4
    	la $a0, error_open
    	syscall
    	li $v0, 0        # Return 0
    	j login_end
	
end_loop:
    	# Close file
    	li $v0, 16
    	move $a0, $s0
    	syscall
	
	# Print result
	beqz $s1, login_fail

    	li $v0, 4
    	la $a0, success_msg
    	syscall

    	li $v0, 4
    	la $a0, user_id_msg
    	syscall
	
    	li $v0, 1
    	lw $a0, userId
    	syscall
	
    	li $v0, 4
    	la $a0, newline
    	syscall
	
    	li $v0, 4
    	la $a0, banknote_msg
    	syscall

    	li $v0, 1
    	lw $a0, banknote
    	syscall

    	li $v0, 4
    	la $a0, newline
    	syscall
	
    	li $v0, 1        # Return 1 (success)
    	j login_end

login_fail:
    	li $v0, 0        # Return 0 (fail)
	
login_end:
    	# Epilogue
    	lw $ra, 0($sp)
    	lw $s0, 4($sp)
    	lw $s1, 8($sp)
    	lw $s2, 12($sp)
    	lw $s3, 16($sp)
    	lw $s4, 20($sp)
    	addi $sp, $sp, 24
    	jr $ra
    	
# String Comparison (strcmp)
# Inputs: $a0 = address of string1, $a1 = address of string2
# Returns: $v0 = 0 (equal), 1 (not equal)
strcmp:
    	# Save registers
    	addi $sp, $sp, -12
    	sw $t0, 0($sp)
    	sw $t1, 4($sp)
    	sw $ra, 8($sp)    # Not strictly needed here, but good practice
    
    	li $v0, 0         # Default to equal
    
strcmp_loop:
    	lb $t0, 0($a0)    # Load byte from string1
    	lb $t1, 0($a1)    # Load byte from string2
    	
    	# Check for end of strings
    	beqz $t0, strcmp_check_end
    	beqz $t1, strcmp_not_equal
    	
    	# Compare characters
    	bne $t0, $t1, strcmp_not_equal
    	
    	# Move to next characters
    	addi $a0, $a0, 1
    	addi $a1, $a1, 1
    	j strcmp_loop
	
strcmp_check_end:
    	# Check if both strings ended
    	beqz $t1, strcmp_end
    	# Fall through to not equal if only string1 ended

strcmp_not_equal:
    	li $v0, 1         # Set not equal
	
strcmp_end:
    	# Restore registers
    	lw $t0, 0($sp)
    	lw $t1, 4($sp)
    	lw $ra, 8($sp)
    	addi $sp, $sp, 12
    	jr $ra

deposit:
	li	$v0, 4
	la	$a0, depositAmountMsg
	syscall
	
	
end_program:	
	
	li	$v0, 10
	syscall	
