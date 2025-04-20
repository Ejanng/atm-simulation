#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>
#include <time.h>

#define MAX_USERS 100


void clearScreen() {
    system("cls");
}

void createAccount() {\
    int banknote = 10000;
    char username[50], password[50];
    FILE *file = fopen("C:/Users/earlj/OneDrive/Documents/c/users.txt", "a");
    if (file == NULL) {
        printf("Error opening file.\n");
        return;
    }

    printf("Enter a username: ");
    scanf("%49s", username);  // safer input
    printf("Enter a password: ");
    scanf("%49s", password);
    // Generate a unique ID for the user
    srand((unsigned int)time(NULL)); // Seed the random number generator
    int userId = rand() % 100000;    // Generate a random ID between 0 and 99999

    // Write the user ID along with the username and password
    if (fprintf(file, "%d %s %s %d\n", userId, username, password, banknote) < 0) {
        printf("Failed to write to file.\n");
    }
    fflush(file); // Force write to disk
    fclose(file);

    printf("Account created successfully for user '%s'!\n", username);
}

int *userIdPtr = NULL, *banknotePtr = NULL; // Declare as global variables
int userId, banknote; // Declare as global variables

int login() {
    char loginUsername[50], loginPassword[50];
    int found = 0;

    printf("Username: ");
    scanf("%s", loginUsername);
    printf("Password: ");
    scanf("%s", loginPassword);

    FILE *file = fopen("users.txt", "r");
    if (file == NULL) {
        printf("Error opening file.\n");
        return 0;
    }
    userIdPtr = &userId;
    banknotePtr = &banknote;
    char storedUsername[50], storedPassword[50];
    while (fscanf(file, "%d %s %s %d", &userId, storedUsername, storedPassword, &banknote) != EOF) {
        if (strcmp(loginUsername, storedUsername) == 0 && strcmp(loginPassword, storedPassword) == 0) {
            found = 1;
            break;
        }
    }
    fclose(file);

    clearScreen();
    if (found) {
        printf("User ID: %d\n", userId);
        printf("Banknote: %d\n", banknote);
    }
    fclose(file);

    return found;
}

// Function to deposit money
void deposit() {
    // Implementation for depositing money
    printf("Deposit function called.\n");
    int depositAmount;
    printf("Enter the amount you want to deposit: ");
    scanf("%d", &depositAmount);

    if (depositAmount <= 0) {
        printf("Invalid deposit amount.\n");
        return;
    }

    FILE *transactionFile = fopen("transactions.txt", "a");
    if (transactionFile != NULL) {
        fprintf(transactionFile, "User: %d deposit a total amount of %d\n", *userIdPtr, depositAmount);
        fclose(transactionFile);
    } else {
        printf("Error opening transaction file.\n");
    }

    FILE *file = fopen("users.txt", "r+");
    if (file == NULL) {
        printf("Error opening file.\n");
        return;
    }

    char storedUsername[50], storedPassword[50];
    int userId, banknote;
    long pos;
    int found = 0;

    while ((pos = ftell(file)) >= 0 && fscanf(file, "%d %s %s %d", &userId, storedUsername, storedPassword, &banknote) != EOF) {
        if (userId == *userIdPtr) { // Match userId with the logged-in user
            banknote += depositAmount;
            fseek(file, pos, SEEK_SET);
            fprintf(file, "%d %s %s %d\n", userId, storedUsername, storedPassword, banknote);
            fflush(file);
            printf("Deposit successful! New balance: %d\n", banknote);
            found = 1;
            break;
        }
    }

    if (!found) {
        printf("User not found.\n");
    }

    fclose(file);
}

// Function to withdraw money
void withdraw() {
    // Implementation for withdrawing money
    printf("Withdraw function called.\n");
    int withdrawAmount;
    printf("Enter the amount you want to withdraw: ");
    scanf("%d", &withdrawAmount);

    if (withdrawAmount <= 0) {
        printf("Invalid withdrawal amount.\n");
        return;
    }

    FILE *file = fopen("users.txt", "r+");
    if (file == NULL) {
        printf("Error opening file.\n");
        return;
    }

    FILE *transactionFile = fopen("transactions.txt", "a");
    if (transactionFile != NULL) {
        fprintf(transactionFile, "User: %d withdrew a total amount of %d\n", *userIdPtr, withdrawAmount);
        fclose(transactionFile);
    } else {
        printf("Error opening transaction file.\n");
    }

    char storedUsername[50], storedPassword[50];
    int userId, banknote;
    long pos;
    int found = 0;

    while ((pos = ftell(file)) >= 0 && fscanf(file, "%d %s %s %d", &userId, storedUsername, storedPassword, &banknote) != EOF) {
        if (userId == *userIdPtr) { // Match userId with the logged-in user
            if (withdrawAmount > banknote) {
                printf("Insufficient balance.\n");
                found = 1;
                break;
            }
            banknote -= withdrawAmount;
            fseek(file, pos, SEEK_SET);
            fprintf(file, "%d %s %s %d\n", userId, storedUsername, storedPassword, banknote);
            fflush(file);
            printf("Withdrawal successful! New balance: %d\n", banknote);
            found = 1;
            break;
        }
    }

    if (!found) {
        printf("User not found.\n");
    }

    fclose(file);
}

typedef struct {
    int id;
    char username[50];
    char password[50];
    int banknote;
} User;

int *userIdPtr;

void transfer() {
    printf("Transfer function called.\n");

    int receiverId, transferAmount;
    printf("Enter the receiver's User ID: ");
    scanf("%d", &receiverId);
    printf("Enter the amount to transfer: ");
    scanf("%d", &transferAmount);

    if (transferAmount <= 0) {
        printf("Invalid transfer amount.\n");
        return;
    }

    FILE *file = fopen("users.txt", "r");
    if (file == NULL) {
        printf("Error opening file.\n");
        return;
    }

    User users[MAX_USERS];
    int userCount = 0;

    // Step 1: Read all users into memory
    while (fscanf(file, "%d %s %s %d", &users[userCount].id, users[userCount].username, users[userCount].password, &users[userCount].banknote) != EOF) {
        userCount++;
        if (userCount >= MAX_USERS) break;
    }
    fclose(file);

    // Step 2: Find sender and receiver
    int senderIndex = -1, receiverIndex = -1;
    for (int i = 0; i < userCount; i++) {
        if (users[i].id == *userIdPtr) senderIndex = i;
        if (users[i].id == receiverId) receiverIndex = i;
    }

    if (senderIndex == -1) {
        printf("Sender not found.\n");
        return;
    }
    if (receiverIndex == -1) {
        printf("Receiver not found.\n");
        return;
    }
    if (users[senderIndex].banknote < transferAmount) {
        printf("Insufficient balance for transfer.\n");
        return;
    }

    // Step 3: Transfer the money
    users[senderIndex].banknote -= transferAmount;
    users[receiverIndex].banknote += transferAmount;

    // Step 4: Write updated users back to the file
    file = fopen("users.txt", "w");
    if (file == NULL) {
        printf("Error writing to file.\n");
        return;
    }

    for (int i = 0; i < userCount; i++) {
        fprintf(file, "%d %s %s %d\n", users[i].id, users[i].username, users[i].password, users[i].banknote);
    }
    fclose(file);

    // Step 5: Log the transaction
    FILE *transactionFile = fopen("transactions.txt", "a");
    if (transactionFile != NULL) {
        fprintf(transactionFile, "User: %d transferred %d to User: %d\n", *userIdPtr, transferAmount, receiverId);
        fclose(transactionFile);
    } else {
        printf("Error opening transaction file.\n");
    }

    printf("Transfer successful! Your new balance: %d\n", users[senderIndex].banknote);
}

void checkInfo() {
    // Implementation for checking balance
    
    printf("Check info function called.\n");
    printf("User ID: %d\n", *userIdPtr);
    printf("Banknote: %d\n", *banknotePtr);
}

void viewTransactionHistory() {
    // Implementation for viewing transaction history
    printf("View transaction history function called.\n");
    FILE *transactionFile = fopen("transactions.txt", "r");
    if (transactionFile == NULL) {
        printf("No transaction history found.\n");
        return;
    }

    char line[256];
    while (fgets(line, sizeof(line), transactionFile)) {
        printf("%s", line);
    }

    fclose(transactionFile);
}

// Function to display the menu
void displayMenu() {
    printf("1. Deposit\n");
    printf("2. Withdraw\n");
    printf("3. Transfer\n");
    printf("4. Check Info\n");
    printf("5. View Transaction History\n");
    printf("6. Logout\n");
}

void displayWelcomeMessage() {
    printf("Welcome to the Banking System!\n");
    printf("1. Create Account\n");
    printf("2. Login\n");
    printf("3. Exit\n");
}

int main() {
    int choice;
    clearScreen();
    displayWelcomeMessage();

    printf("Enter your choice: ");
    scanf("%d", &choice);

    switch (choice) {
        case 1:
            // Register a new user
            clearScreen();
            createAccount();
            break;
        case 2:
            // Login
            clearScreen();
            printf("Login to your account\n");
            if (login()) {
                int operation;
                printf("Login successful!\n");

                while (1) {
                    displayMenu();
                    printf("Enter : ");
                    scanf("%d", &operation);

                    switch (operation) {
                        case 1:
                            deposit();
                            break;
                        case 2:
                            withdraw();
                            break;
                        case 3:
                            transfer();
                            break;
                        case 4:
                            checkInfo();
                            break;
                        case 5:
                            viewTransactionHistory();
                            break;
                        case 6:
                            printf("Logging out...\n");
                            return 0; // Exit the loop and go back to the main menu
                        default:
                            printf("Invalid operation.\n");
                    }
                }
            // Proceed to banking operations
            } else {
                printf("Invalid username or password.\n");
            }
            break;
        case 3:
            // Exit
            return 0;
        default:
            printf("Invalid choice\n");
            break;
    }

    return 0;
    
}
