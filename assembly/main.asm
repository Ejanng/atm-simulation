# Banking System in MIPS Assembly
# Data is stored in memory (no file I/O)
# Supports: account creation, login, deposits, withdrawals, transfers, transaction history
# Admin functions: view all users, view all transactions

.data
# Constants
MAX_USERS:          .word 100
MAX_TRANSACTIONS:   .word 1000
INITIAL_BALANCE:    .word 10000

# User data structure (each user is 64 bytes)
# 0-3: id (word)
# 4-53: username (50 bytes)
# 54-103: password (50 bytes)
# 104-107: balance (word)
USER_SIZE:          .word 108

# Transaction data structure (each transaction is 24 bytes)
# 0-3: userId (word)
# 4-7: otherUserId (word)
# 8-27: type (20 bytes)
# 28-31: amount (word)
# 32-35: timestamp (word)
TRANSACTION_SIZE:   .word 36

# Global variables
users:              .space 10800      # 100 users * 108 bytes
transactions:       .space 36000      # 1000 transactions * 36 bytes
userCount:          .word 0
transactionCount:   .word 0
currentUserId:      .word -1          # -1 means no user logged in
adminLoggedIn:      .word 0           # 0 means no admin logged in

# String constants
newline:            .asciiz "\n"
tab:                .asciiz "\t"
colon:              .asciiz ": "
comma:              .asciiz ", "
space:              .asciiz " "
dash:               .asciiz "-"
slash:              .asciiz "/"

# Menu strings
mainMenu:           .asciiz "\nMain Menu\n1. Create Account\n2. Login\n3. Admin Login\n4. Exit\nEnter your choice: "
userMenu:           .asciiz "\nBanking Menu\n1. Deposit\n2. Withdraw\n3. Transfer\n4. Check Info\n5. Transaction History\n6. Logout\nEnter your choice: "
adminMenu:          .asciiz "\nAdmin Menu\n1. View All Users\n2. View All Transactions\n3. Logout\nEnter your choice: "

# Prompt strings
promptUsername:     .asciiz "Enter username: "
promptPassword:     .asciiz "Enter password: "
promptAmount:       .asciiz "Enter amount: "
promptReceiverId:   .asciiz "Enter receiver's User ID: "
promptAdminUser:    .asciiz "Admin username: "
promptAdminPass:    .asciiz "Admin password: "

# Message strings
msgWelcome:         .asciiz "Welcome to the Banking System!"
msgAccountCreated:  .asciiz "Account created successfully!"
msgYourId:          .asciiz "Your User ID is: "
msgYourBalance:     .asciiz "Your initial balance is: "
msgLoginSuccess:    .asciiz "Login successful!"
msgWelcomeUser:     .asciiz "Welcome, "
msgAdminSuccess:    .asciiz "Admin login successful!"
msgInvalidCred:     .asciiz "Invalid username or password."
msgInvalidAdmin:    .asciiz "Invalid admin credentials."
msgDepositSuccess:  .asciiz "Deposit successful. New balance: "
msgWithdrawSuccess: .asciiz "Withdrawal successful. New balance: "
msgInsufficient:    .asciiz "Insufficient funds."
msgInvalidAmount:   .asciiz "Invalid amount."
msgTransferSuccess: .asciiz "Transfer successful. New balance: "
msgReceiverNotFound:.asciiz "Receiver not found."
msgCannotSelf:      .asciiz "Cannot transfer to yourself."
msgUserNotFound:    .asciiz "User not found."
msgLoggedOut:       .asciiz "Logged out successfully."
msgAdminLoggedOut:  .asciiz "Admin logged out successfully."
msgNoTransactions:  .asciiz "No transactions found."
msgMaxUsers:        .asciiz "Maximum number of users reached."

# Info headers
headerAccount:      .asciiz "\nAccount Information"
headerUserId:       .asciiz "User ID: "
headerUsername:     .asciiz "Username: "
headerBalance:      .asciiz "Balance: "
headerTransactions: .asciiz "\nTransaction History\n------------------"
headerAllUsers:     .asciiz "\nAll Users\nID\tUsername\tBalance"
headerAllTrans:     .asciiz "\nAll Transactions\nTimestamp\t\tType\t\tAmount\tFrom\tTo"

# Transaction types
typeDeposit:        .asciiz "deposit"
typeWithdraw:       .asciiz "withdraw"
typeTransfer:       .asciiz "transfer"
typeSent:           .asciiz "Sent "
typeReceived:       .asciiz "Received "
typeTo:             .asciiz " to User "
typeFrom:           .asciiz " from User "

# Admin credentials
adminUsername:      .asciiz "admin"
adminPassword:      .asciiz "admin123"

# Buffers
buffer:             .space 64
usernameBuffer:     .space 50
passwordBuffer:     .space 50

.text
.globl main

main:
    # Initialize the system with one admin account
    j initAdminAccount
    
main_loop:
    # Display main menu
    li $v0, 4
    la $a0, msgWelcome
    syscall
    
    li $v0, 4
    la $a0, mainMenu
    syscall
    
    # Get user choice
    li $v0, 5
    syscall
    move $t0, $v0
    
    # Process choice
    beq $t0, 1, create_account
    beq $t0, 2, login_user
    beq $t0, 3, login_admin
    beq $t0, 4, exit_program
    
    j main_loop

create_account:
    # Check if we've reached max users
    lw $t0, userCount
    lw $t1, MAX_USERS
    bge $t0, $t1, max_users_reached
    
    # Prompt for username
    li $v0, 4
    la $a0, promptUsername
    syscall
    
    li $v0, 8
    la $a0, usernameBuffer
    li $a1, 50
    syscall
    
    # Remove newline from username
    la $a0, usernameBuffer
    j remove_newline
    
after_username_clean:
    # Check if username already exists
    la $a0, usernameBuffer
    j username_exists
    
after_username_check:
    beq $v0, 1, username_taken
    
    # Prompt for password
    li $v0, 4
    la $a0, promptPassword
    syscall
    
    li $v0, 8
    la $a0, passwordBuffer
    li $a1, 50
    syscall
    
    # Remove newline from password
    la $a0, passwordBuffer
    j remove_newline
    
after_password_clean:
    # Create the account
    j add_user
    
after_account_creation:
    # Display success message
    li $v0, 4
    la $a0, msgAccountCreated
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    li $v0, 4
    la $a0, msgYourId
    syscall
    
    # Display user ID
    lw $a0, buffer    # ID was stored in buffer by add_user
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    li $v0, 4
    la $a0, msgYourBalance
    syscall
    
    # Display initial balance
    lw $a0, INITIAL_BALANCE
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    j main_loop

username_taken:
    li $v0, 4
    la $a0, msgInvalidCred
    syscall
    j main_loop

max_users_reached:
    li $v0, 4
    la $a0, msgMaxUsers
    syscall
    j main_loop

login_user:
    # Prompt for username
    li $v0, 4
    la $a0, promptUsername
    syscall
    
    li $v0, 8
    la $a0, usernameBuffer
    li $a1, 50
    syscall
    
    # Remove newline from username
    jal remove_newline
    
    # Prompt for password
    li $v0, 4
    la $a0, promptPassword
    syscall
    
    li $v0, 8
    la $a0, passwordBuffer
    li $a1, 50
    syscall
    
    # Remove newline from password
    jal remove_newline
    
    # Try to login
    la $a0, usernameBuffer
    la $a1, passwordBuffer
    jal authenticate_user
    
    beq $v0, -1, invalid_credentials
    
    # Login successful
    sw $v0, currentUserId
    
    li $v0, 4
    la $a0, msgLoginSuccess
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Display welcome message with username
    li $v0, 4
    la $a0, msgWelcomeUser
    syscall
    
    li $v0, 4
    la $a0, usernameBuffer
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Enter user menu
    j user_menu

invalid_credentials:
    li $v0, 4
    la $a0, msgInvalidCred
    syscall
    j main_loop

login_admin:
    # Prompt for admin username
    li $v0, 4
    la $a0, promptAdminUser
    syscall
    
    li $v0, 8
    la $a0, usernameBuffer
    li $a1, 50
    syscall
    
    # Remove newline from username
    jal remove_newline
    
    # Prompt for admin password
    li $v0, 4
    la $a0, promptAdminPass
    syscall
    
    li $v0, 8
    la $a0, passwordBuffer
    li $a1, 50
    syscall
    
    # Remove newline from password
    jal remove_newline
    
    # Check admin credentials
    la $a0, adminUsername
    la $a1, usernameBuffer
    jal strcmp
    bne $v0, 0, admin_invalid
    
    la $a0, adminPassword
    la $a1, passwordBuffer
    jal strcmp
    bne $v0, 0, admin_invalid
    
    # Admin login successful
    li $t0, 1
    sw $t0, adminLoggedIn
    
    li $v0, 4
    la $a0, msgAdminSuccess
    syscall
    
    # Enter admin menu
    j admin_menu

admin_invalid:
    li $v0, 4
    la $a0, msgInvalidAdmin
    syscall
    j main_loop

user_menu:
    # Display user menu
    li $v0, 4
    la $a0, userMenu
    syscall
    
    # Get user choice
    li $v0, 5
    syscall
    move $t0, $v0
    
    # Process choice
    beq $t0, 1, deposit
    beq $t0, 2, withdraw
    beq $t0, 3, transfer
    beq $t0, 4, check_info
    beq $t0, 5, transaction_history
    beq $t0, 6, logout_user
    
    j user_menu

admin_menu:
    # Display admin menu
    li $v0, 4
    la $a0, adminMenu
    syscall
    
    # Get admin choice
    li $v0, 5
    syscall
    move $t0, $v0
    
    # Process choice
    beq $t0, 1, admin_view_users
    beq $t0, 2, admin_view_transactions
    beq $t0, 3, logout_admin
    
    j admin_menu

deposit:
    # Prompt for amount
    li $v0, 4
    la $a0, promptAmount
    syscall
    
    li $v0, 5
    syscall
    move $a1, $v0
    
    # Validate amount
    blez $a1, invalid_amount
    
    # Process deposit
    lw $a0, currentUserId
    jal add_transaction_deposit
    
    # Display success message
    li $v0, 4
    la $a0, msgDepositSuccess
    syscall
    
    # Get and display new balance
    lw $a0, currentUserId
    jal get_user_balance
    move $a0, $v0
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    j user_menu

withdraw:
    # Prompt for amount
    li $v0, 4
    la $a0, promptAmount
    syscall
    
    li $v0, 5
    syscall
    move $a1, $v0
    
    # Validate amount
    blez $a1, invalid_amount
    
    # Check sufficient funds
    lw $a0, currentUserId
    jal get_user_balance
    move $t0, $v0
    
    blt $t0, $a1, insufficient_funds
    
    # Process withdrawal
    lw $a0, currentUserId
    move $a1, $a1
    jal add_transaction_withdraw
    
    # Display success message
    li $v0, 4
    la $a0, msgWithdrawSuccess
    syscall
    
    # Get and display new balance
    lw $a0, currentUserId
    jal get_user_balance
    move $a0, $v0
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    j user_menu

transfer:
    # Prompt for receiver ID
    li $v0, 4
    la $a0, promptReceiverId
    syscall
    
    li $v0, 5
    syscall
    move $t1, $v0      # $t1 = receiver ID
    
    # Check if transferring to self
    lw $t0, currentUserId
    beq $t0, $t1, transfer_to_self
    
    # Prompt for amount
    li $v0, 4
    la $a0, promptAmount
    syscall
    
    li $v0, 5
    syscall
    move $t2, $v0      # $t2 = amount
    
    # Validate amount
    blez $t2, invalid_amount
    
    # Check sufficient funds
    move $a0, $t0
    jal get_user_balance
    move $t3, $v0
    
    blt $t3, $t2, insufficient_funds
    
    # Check if receiver exists
    move $a0, $t1
    jal find_user_by_id
    beq $v0, -1, receiver_not_found
    
    # Process transfer
    lw $a0, currentUserId
    move $a1, $t1      # receiver ID
    move $a2, $t2      # amount
    jal add_transaction_transfer
    
    # Display success message
    li $v0, 4
    la $a0, msgTransferSuccess
    syscall
    
    # Get and display new balance
    lw $a0, currentUserId
    jal get_user_balance
    move $a0, $v0
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    j user_menu

transfer_to_self:
    li $v0, 4
    la $a0, msgCannotSelf
    syscall
    j user_menu

receiver_not_found:
    li $v0, 4
    la $a0, msgReceiverNotFound
    syscall
    j user_menu

insufficient_funds:
    li $v0, 4
    la $a0, msgInsufficient
    syscall
    j user_menu

invalid_amount:
    li $v0, 4
    la $a0, msgInvalidAmount
    syscall
    j user_menu

check_info:
    # Display account info header
    li $v0, 4
    la $a0, headerAccount
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Display user ID
    li $v0, 4
    la $a0, headerUserId
    syscall
    
    lw $a0, currentUserId
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Display username
    li $v0, 4
    la $a0, headerUsername
    syscall
    
    lw $a0, currentUserId
    jal get_username
    move $a0, $v0
    li $v0, 4
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Display balance
    li $v0, 4
    la $a0, headerBalance
    syscall
    
    lw $a0, currentUserId
    jal get_user_balance
    move $a0, $v0
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    j user_menu

transaction_history:
    # Display header
    li $v0, 4
    la $a0, headerTransactions
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Get current user ID
    lw $a0, currentUserId
    
    # Get transaction history for this user
    jal get_user_transactions
    
    # $v0 = number of transactions found
    beqz $v0, no_transactions
    
    j user_menu

no_transactions:
    li $v0, 4
    la $a0, msgNoTransactions
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    j user_menu

admin_view_users:
    # Display header
    li $v0, 4
    la $a0, headerAllUsers
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Display all users
    jal display_all_users
    
    j admin_menu

admin_view_transactions:
    # Display header
    li $v0, 4
    la $a0, headerAllTrans
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Display all transactions
    jal display_all_transactions
    
    j admin_menu

logout_user:
    li $v0, 4
    la $a0, msgLoggedOut
    syscall
    
    # Reset current user
    li $t0, -1
    sw $t0, currentUserId
    
    j main_loop

logout_admin:
    li $v0, 4
    la $a0, msgAdminLoggedOut
    syscall
    
    # Reset admin login
    sw $zero, adminLoggedIn
    
    j main_loop

exit_program:
    li $v0, 10
    syscall

# Helper functions

initAdminAccount:
    # Initialize the admin account
    la $t0, users
    
    # Set admin ID (99999)
    li $t1, 99999
    sw $t1, 0($t0)
    
    # Copy admin username
    la $t1, adminUsername
    addi $t2, $t0, 4
    jal strcpy
    
    # Copy admin password
    la $t1, adminPassword
    addi $t2, $t0, 54
    jal strcpy
    
    # Set admin balance to 0
    sw $zero, 104($t0)
    
    # Increment user count
    li $t1, 1
    sw $t1, userCount
    
    j main_loop

remove_newline:
    # Remove newline from string in $a0
    move $t0, $a0
    
remove_newline_loop:
    lb $t1, 0($t0)
    beqz $t1, remove_newline_done    # Check for null terminator
    beq $t1, 10, replace_newline    # 10 is ASCII for newline
    addi $t0, $t0, 1
    j remove_newline_loop

replace_newline:
    sb $zero, 0($t0)  # Replace newline with null terminator

remove_newline_done:
    j after_username_clean

username_exists:
    # Check if username in $a0 exists
    # Returns 1 if exists, 0 otherwise
    la $t0, users
    lw $t1, userCount
    li $v0, 0
    
    beqz $t1, username_exists_done  # If no users, username doesn't exist
    
    li $t2, 0  # counter
    
username_exists_loop:
    # Get username address for this user
    mul $t3, $t2, 108
    add $t3, $t0, $t3
    addi $t3, $t3, 4  # username field
    
    # Save original a0 (input username)
    move $t4, $a0
    
    # Compare strings
    move $a1, $t3
    jal strcmp
    
    # Restore original a0
    move $a0, $t4
    
    beqz $v0, username_found  # If strcmp returns 0, usernames match
    
    addi $t2, $t2, 1
    blt $t2, $t1, username_exists_loop
    
    j username_exists_done

username_found:
    li $v0, 1

username_exists_done:
    j after_username_check

strcmp:
    # Compare strings at $a0 and $a1
    # Returns 0 if equal, 1 otherwise
    li $v0, 0
    
strcmp_loop:
    lb $t0, 0($a0)
    lb $t1, 0($a1)
    bne $t0, $t1, strcmp_not_equal
    beqz $t0, strcmp_done
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    j strcmp_loop

strcmp_not_equal:
    li $v0, 1

strcmp_done:
    jr $ra

strcpy:
    # Add NULL pointer check
    beqz $a1, strcpy_fail  # Check if source is NULL
    beqz $a0, strcpy_fail  # Check if destination is NULL
    
    move $t0, $a0  # destination
    move $t1, $a1  # source

strcpy_loop:
    lb $v0, 0($t1)     # Load byte from source
    beqz $v0, strcpy_done  # Check for NULL terminator first
    sb $v0, 0($t0)     # Store byte to destination
    addi $t1, $t1, 1   # Increment source pointer
    addi $t0, $t0, 1   # Increment destination pointer
    j strcpy_loop

strcpy_done:
    sb $zero, 0($t0)   # Ensure NULL termination
    jr $ra

strcpy_fail:
    li $v0, -1         # Return error code
    jr $ra

add_user:
    # Prologue
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    
    # Check if we've reached max users
    lw $t0, userCount
    lw $t1, MAX_USERS
    bge $t0, $t1, max_userss_reached
    
    la $s0, users
    move $s1, $t0      # current count
    
    # Calculate offset (108 bytes per user)
    li $t2, 108
    mul $t0, $s1, $t2
    add $t0, $s0, $t0  # $t0 = new user address
    
    # Generate user ID (10000-99999)
    li $v0, 42
    li $a0, 0
    li $a1, 90000
    addi $a0, $a0, 10000
    sw $a0, 0($t0)     # store user ID
    
    # Copy username (validate buffer first)
    la $t1, usernameBuffer
    lb $t2, 0($t1)     # check first byte
    beqz $t2, invalid_username
    
    addi $a0, $t0, 4   # username field
    move $a1, $t1
    jal strcpy
    
    # Copy password (validate buffer first)
    la $t1, passwordBuffer
    lb $t2, 0($t1)     # check first byte
    beqz $t2, invalid_password
    
    addi $a0, $t0, 54  # password field
    move $a1, $t1
    jal strcpy
    
    # Set initial balance
    lw $t1, INITIAL_BALANCE
    sw $t1, 104($t0)
    
    # Increment user count
    addi $s1, $s1, 1
    sw $s1, userCount
    
    # Return user ID in buffer
    lw $t2, 0($t0)
    sw $t2, buffer
    
    # Epilogue
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra

max_userss_reached:
    la $a0, msgMaxUsers
    li $v0, 4
    syscall
    j add_user_end

invalid_username:
invalid_password:
    # Handle error cases here
add_user_end:
    # Clean up and return
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra

authenticate_user:
    # Prologue - save registers
    addi $sp, $sp, -8
    sw $a0, 0($sp)     # Save original username pointer
    sw $a1, 4($sp)     # Save original password pointer
    
    la $t0, users
    lw $t1, userCount
    li $v0, -1
    
    beqz $t1, authenticate_done
    
    li $t2, 0  # counter
    
authenticate_loop:
    # Get username address for this user
    mul $t3, $t2, 108
    add $t3, $t0, $t3
    addi $t3, $t3, 4
    
    # Compare username
    move $a1, $a0      # $a1 = input username
    move $a0, $t3      # $a0 = stored username
    jal strcmp
    
    # Restore $a0 after strcmp
    lw $a0, 0($sp)
    
    beqz $v0, check_password
    
    addi $t2, $t2, 1
    blt $t2, $t1, authenticate_loop
    
    j authenticate_done

check_password:
    # Username matched, now check password
    mul $t3, $t2, 108
    add $t3, $t0, $t3
    addi $t3, $t3, 54  # password offset
    
    move $a0, $t3
    lw $a1, 4($sp)     # Get original password pointer
    jal strcmp
    
    # Restore $a0 after strcmp
    lw $a0, 0($sp)
    
    beqz $v0, authentication_success
    
    # Password didn't match, continue searching
    addi $t2, $t2, 1
    blt $t2, $t1, authenticate_loop
    
    j authenticate_done

authentication_success:
    # Get user ID
    mul $t3, $t2, 108
    add $t3, $t0, $t3
    lw $v0, 0($t3)

authenticate_done:
    # Epilogue - restore stack
    addi $sp, $sp, 8
    jr $ra

find_user_by_id:
    # Find user by ID ($a0)
    # Returns user index if found, -1 otherwise
    la $t0, users
    lw $t1, userCount
    li $v0, -1
    
    beqz $t1, find_user_done
    
    li $t2, 0  # counter
    
find_user_loop:
    mul $t3, $t2, 108
    add $t3, $t0, $t3
    lw $t4, 0($t3)
    
    beq $t4, $a0, user_found
    
    addi $t2, $t2, 1
    blt $t2, $t1, find_user_loop
    
    j find_user_done

user_found:
    move $v0, $t2

find_user_done:
    jr $ra

get_user_balance:
    # Get balance for user ID ($a0)
    # Returns balance in $v0
    jal find_user_by_id
    beq $v0, -1, user_not_found_error
    
    mul $t0, $v0, 108
    la $t1, users
    add $t1, $t1, $t0
    lw $v0, 104($t1)
    
    jr $ra

user_not_found_error:
    li $v0, 4
    la $a0, msgUserNotFound
    syscall
    li $v0, -1
    jr $ra

get_username:
    # Get username for user ID ($a0)
    # Returns pointer to username in $v0
    jal find_user_by_id
    beq $v0, -1, user_not_found_error
    
    mul $t0, $v0, 108
    la $v0, users
    add $v0, $v0, $t0
    addi $v0, $v0, 4
    
    jr $ra

add_transaction_deposit:
    # Add deposit transaction for user ($a0) with amount ($a1)
    la $t0, transactions
    lw $t1, transactionCount
    mul $t2, $t1, 36
    add $t2, $t0, $t2
    
    # Store user ID
    sw $a0, 0($t2)
    
    # Store other user ID as -1
    li $t3, -1
    sw $t3, 4($t2)
    
    # Store transaction type
    la $t3, typeDeposit
    addi $t4, $t2, 8
    move $t1, $t3
    move $t2, $t4
    jal strcpy
    
    # Store amount
    sw $a1, 28($t2)
    
    # Store timestamp (just use a counter for simplicity)
    lw $t0, transactionCount
    sw $t0, 32($t2)
    
    # Update user balance
    move $a2, $a1
    li $a1, 0  # 0 means add to balance
    jal update_user_balance
    
    # Increment transaction count
    lw $t0, transactionCount
    addi $t0, $t0, 1
    sw $t0, transactionCount
    
    jr $ra

add_transaction_withdraw:
    # Add withdrawal transaction for user ($a0) with amount ($a1)
    la $t0, transactions
    lw $t1, transactionCount
    mul $t2, $t1, 36
    add $t2, $t0, $t2
    
    # Store user ID
    sw $a0, 0($t2)
    
    # Store other user ID as -1
    li $t3, -1
    sw $t3, 4($t2)
    
    # Store transaction type
    la $t3, typeWithdraw
    addi $t4, $t2, 8
    move $t1, $t3
    move $t2, $t4
    jal strcpy
    
    # Store amount
    sw $a1, 28($t2)
    
    # Store timestamp
    lw $t0, transactionCount
    sw $t0, 32($t2)
    
    # Update user balance
    move $a2, $a1
    li $a1, 1  # 1 means subtract from balance
    jal update_user_balance
    
    # Increment transaction count
    lw $t0, transactionCount
    addi $t0, $t0, 1
    sw $t0, transactionCount
    
    jr $ra

add_transaction_transfer:
    # Add transfer transaction from user ($a0) to user ($a1) with amount ($a2)
    la $t0, transactions
    lw $t1, transactionCount
    mul $t2, $t1, 36
    add $t2, $t0, $t2
    
    # Store sender ID
    sw $a0, 0($t2)
    
    # Store receiver ID
    sw $a1, 4($t2)
    
    # Store transaction type
    la $t3, typeTransfer
    addi $t4, $t2, 8
    move $t1, $t3
    move $t2, $t4
    jal strcpy
    
    # Store amount
    sw $a2, 28($t2)
    
    # Store timestamp
    lw $t0, transactionCount
    sw $t0, 32($t2)
    
    # Update sender balance (subtract)
    move $a0, $a0
    li $a1, 1  # subtract
    move $a2, $a2
    jal update_user_balance
    
    # Update receiver balance (add)
    move $a0, $a1
    li $a1, 0  # add
    move $a2, $a2
    jal update_user_balance
    
    # Increment transaction count
    lw $t0, transactionCount
    addi $t0, $t0, 1
    sw $t0, transactionCount
    
    jr $ra

update_user_balance:
    # Update balance for user ($a0)
    # $a1: 0=add, 1=subtract
    # $a2: amount
    jal find_user_by_id
    beq $v0, -1, update_balance_done
    
    mul $t0, $v0, 108
    la $t1, users
    add $t1, $t1, $t0
    lw $t2, 104($t1)  # current balance
    
    beqz $a1, add_to_balance
    
    # Subtract from balance
    sub $t2, $t2, $a2
    j store_new_balance
    
add_to_balance:
    # Add to balance
    add $t2, $t2, $a2
    
store_new_balance:
    sw $t2, 104($t1)

update_balance_done:
    jr $ra

get_user_transactions:
    # Get transactions for user ($a0)
    # Returns count in $v0
    la $t0, transactions
    lw $t1, transactionCount
    li $v0, 0
    
    beqz $t1, get_transactions_done
    
    li $t2, 0  # counter
    li $t3, 0  # found count
    
get_transactions_loop:
    mul $t4, $t2, 36
    add $t4, $t0, $t4
    
    # Check if this transaction involves our user
    lw $t5, 0($t4)  # user ID
    beq $t5, $a0, transaction_found
    
    lw $t5, 4($t4)  # other user ID
    beq $t5, $a0, transaction_found
    
    j next_transaction

transaction_found:
    # Display transaction
    addi $t3, $t3, 1
    
    # Display timestamp (just using transaction number for simplicity)
    li $v0, 1
    lw $a0, 32($t4)
    syscall
    
    li $v0, 4
    la $a0, colon
    syscall
    
    # Check transaction type
    addi $t6, $t4, 8  # pointer to type string
    
    # Compare with "transfer"
    la $a0, typeTransfer
    move $a1, $t6
    jal strcmp
    beqz $v0, display_transfer
    
    # Not a transfer, just display type and amount
    move $a0, $t6
    li $v0, 4
    syscall
    
    li $v0, 4
    la $a0, space
    syscall
    
    li $v0, 1
    lw $a0, 28($t4)
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    j next_transaction

display_transfer:
    # Check if user is sender or receiver
    lw $t7, 0($t4)  # user ID
    beq $t7, $a0, display_sent_transfer
    
    # User is receiver
    li $v0, 4
    la $a0, typeReceived
    syscall
    
    li $v0, 1
    lw $a0, 28($t4)
    syscall
    
    li $v0, 4
    la $a0, typeFrom
    syscall
    
    li $v0, 1
    lw $a0, 0($t4)  # sender ID
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    j next_transaction

display_sent_transfer:
    # User is sender
    li $v0, 4
    la $a0, typeSent
    syscall
    
    li $v0, 1
    lw $a0, 28($t4)
    syscall
    
    li $v0, 4
    la $a0, typeTo
    syscall
    
    li $v0, 1
    lw $a0, 4($t4)  # receiver ID
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall

next_transaction:
    addi $t2, $t2, 1
    blt $t2, $t1, get_transactions_loop

get_transactions_done:
    move $v0, $t3
    jr $ra

display_all_users:
    # Display all users in the system
    la $t0, users
    lw $t1, userCount
    
    beqz $t1, display_users_done
    
    li $t2, 0  # counter
    
display_users_loop:
    mul $t3, $t2, 108
    add $t3, $t0, $t3
    
    # Display user ID
    li $v0, 1
    lw $a0, 0($t3)
    syscall
    
    li $v0, 4
    la $a0, tab
    syscall
    
    # Display username
    addi $a0, $t3, 4
    li $v0, 4
    syscall
    
    li $v0, 4
    la $a0, tab
    syscall
    
    # Display balance
    li $v0, 1
    lw $a0, 104($t3)
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    addi $t2, $t2, 1
    blt $t2, $t1, display_users_loop

display_users_done:
    jr $ra

display_all_transactions:
    # Display all transactions in the system
    la $t0, transactions
    lw $t1, transactionCount
    
    beqz $t1, display_trans_done
    
    li $t2, 0  # counter
    
display_trans_loop:
    mul $t3, $t2, 36
    add $t3, $t0, $t3
    
    # Display timestamp (using transaction number)
    li $v0, 1
    lw $a0, 32($t3)
    syscall
    
    li $v0, 4
    la $a0, tab
    syscall
    
    # Display transaction type
    addi $a0, $t3, 8
    li $v0, 4
    syscall
    
    li $v0, 4
    la $a0, tab
    syscall
    
    # Display amount
    li $v0, 1
    lw $a0, 28($t3)
    syscall
    
    li $v0, 4
    la $a0, tab
    syscall
    
    # Display from user ID
    li $v0, 1
    lw $a0, 0($t3)
    syscall
    
    li $v0, 4
    la $a0, tab
    syscall
    
    # Display to user ID (if transfer)
    lw $t4, 4($t3)
    beq $t4, -1, display_dash
    
    li $v0, 1
    move $a0, $t4
    syscall
    j display_trans_next
    
display_dash:
    li $v0, 4
    la $a0, dash
    syscall
    
display_trans_next:
    li $v0, 4
    la $a0, newline
    syscall
    
    addi $t2, $t2, 1
    blt $t2, $t1, display_trans_loop

display_trans_done:
    jr $ra

# End of program
