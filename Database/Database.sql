DROP DATABASE IF EXISTS library_db;
CREATE DATABASE library_db;
USE library_db;


-- Member Table
CREATE TABLE Member (
    member_ID INT PRIMARY KEY AUTO_INCREMENT,
    Password VARCHAR(255) NOT NULL,
    First_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    Email VARCHAR(150) UNIQUE NOT NULL,
    membership_date DATE DEFAULT (CURRENT_DATE),
    Phone_number VARCHAR(20),
    address VARCHAR(255),
    membership_cost DECIMAL(10,2) DEFAULT 10.00,
    CHECK (membership_cost >= 10),
    CHECK (LENGTH(Password) >= 8) -- Enforce min password length
);

-- Librarian Table
CREATE TABLE Librarian (
    Libarian_ID INT PRIMARY KEY AUTO_INCREMENT,
    Password VARCHAR(255) NOT NULL,
    Email VARCHAR(150) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    CHECK (LENGTH(Password) >= 8)
);

-- Books Table
CREATE TABLE Books (
    Book_ID INT PRIMARY KEY AUTO_INCREMENT,
    ISBN VARCHAR(20) UNIQUE,
    Title VARCHAR(255) NOT NULL,
    Publisher VARCHAR(150),
    Publication_year INT,
    Author VARCHAR(150) NOT NULL,
    shelf_location VARCHAR(50),
    Status VARCHAR(50) DEFAULT 'Available',
    Price DECIMAL(10,2),
    CHECK (Status IN ('Available', 'Borrowed', 'Reserved', 'Lost'))
);

-- BookCategory Table
CREATE TABLE BookCategory (
    Book_ID INT,
    Categories VARCHAR(100),
    PRIMARY KEY (Book_ID, Categories),
    FOREIGN KEY (Book_ID) REFERENCES Books(Book_ID) ON DELETE CASCADE
);

-- Reservations Table
CREATE TABLE Reservations (
    reservation_ID INT PRIMARY KEY AUTO_INCREMENT,
    Member_ID INT NOT NULL,
    Book_ID INT NOT NULL,
    Status VARCHAR(50) DEFAULT 'Active',
    Reservation_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    queue_position INT,
    FOREIGN KEY (Member_ID) REFERENCES Member(member_ID),
    FOREIGN KEY (Book_ID) REFERENCES Books(Book_ID)
);

-- Loans Table
CREATE TABLE Loans (
    LoanID INT PRIMARY KEY AUTO_INCREMENT,
    Book_ID INT NOT NULL,
    Member_ID INT NOT NULL,
    Borrow_date DATE DEFAULT (CURRENT_DATE),
    Due_date DATE NOT NULL,
    Return_date DATE,
    fine_amount DECIMAL(10,2) DEFAULT 0.00,
    fine_status VARCHAR(50) DEFAULT 'None',
    FOREIGN KEY (Book_ID) REFERENCES Books(Book_ID),
    FOREIGN KEY (Member_ID) REFERENCES Member(member_ID)
);


DELIMITER //

-- Trigger 1: Check reservation limit (Max 3 active per member)
CREATE TRIGGER check_reservation_limit
BEFORE INSERT ON Reservations
FOR EACH ROW
BEGIN
    DECLARE res_count INT;
    SELECT COUNT(*) INTO res_count
    FROM Reservations
    WHERE Member_ID = NEW.Member_ID AND Status = 'Active';
    
    IF res_count >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot reserve more than 3 books';
    END IF;
END//

-- Trigger 2: Set queue position for reservations
CREATE TRIGGER set_queue_position
BEFORE INSERT ON Reservations
FOR EACH ROW
BEGIN
    DECLARE max_pos INT;
    SELECT COALESCE(MAX(queue_position), 0) INTO max_pos
    FROM Reservations
    WHERE Book_ID = NEW.Book_ID AND Status = 'Active';
    
    SET NEW.queue_position = max_pos + 1;
END//

-- Trigger 3: Validate Loan (Check Availability & Reservations)
CREATE TRIGGER check_loan_validity
BEFORE INSERT ON Loans
FOR EACH ROW
BEGIN
    DECLARE book_status VARCHAR(50);
    DECLARE reserver_id INT;

    -- Get current book status
    SELECT Status INTO book_status FROM Books WHERE Book_ID = NEW.Book_ID;

    -- Block if already borrowed
    IF book_status = 'Borrowed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book is currently borrowed';
    END IF;

    -- Block if Reserved by someone else
    IF book_status = 'Reserved' THEN
        -- Find who is #1 in the queue
        SELECT Member_ID INTO reserver_id 
        FROM Reservations 
        WHERE Book_ID = NEW.Book_ID AND Status = 'Active' 
        ORDER BY queue_position ASC LIMIT 1;
        
        -- If the borrower is NOT the person who reserved it, block them
        IF NEW.Member_ID != reserver_id THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book is reserved by another member';
        END IF;
    END IF;
END//

-- Trigger 4: Update Book Status to 'Borrowed' on Loan
CREATE TRIGGER update_status_on_loan
AFTER INSERT ON Loans
FOR EACH ROW
BEGIN
    -- Mark book as borrowed
    UPDATE Books SET Status = 'Borrowed' WHERE Book_ID = NEW.Book_ID;
    
    -- If this was a reservation fulfillment, mark reservation as Completed
    UPDATE Reservations 
    SET Status = 'Completed' 
    WHERE Book_ID = NEW.Book_ID AND Member_ID = NEW.Member_ID AND Status = 'Active';
END//

-- Trigger 5: Update Book Status on Return & Check for Pending Reservations
CREATE TRIGGER update_book_returned
AFTER UPDATE ON Loans
FOR EACH ROW
BEGIN
    DECLARE pending_res INT;

    -- Only run if the book is being returned now (was NULL, now has a date)
    IF NEW.Return_date IS NOT NULL AND OLD.Return_date IS NULL THEN
        -- Check if anyone is waiting for this book
        SELECT COUNT(*) INTO pending_res FROM Reservations WHERE Book_ID = NEW.Book_ID AND Status = 'Active';

        IF pending_res > 0 THEN
            UPDATE Books SET Status = 'Reserved' WHERE Book_ID = NEW.Book_ID;
        ELSE
            UPDATE Books SET Status = 'Available' WHERE Book_ID = NEW.Book_ID;
        END IF;
    END IF;
END//

-- Trigger 6: Calculate Fine on Return
CREATE TRIGGER calculate_fine
BEFORE UPDATE ON Loans
FOR EACH ROW
BEGIN
    DECLARE weeks_late INT;
    
    IF NEW.Return_date IS NOT NULL AND OLD.Return_date IS NULL THEN
        IF NEW.Return_date > NEW.Due_date THEN
            -- Calculate weeks late (rounded up)
            SET weeks_late = CEIL(DATEDIFF(NEW.Return_date, NEW.Due_date) / 7.0);
            SET NEW.fine_amount = weeks_late * 100; -- 100 currency units per week
            SET NEW.fine_status = 'Pending';
        END IF;
    END IF;
END//

DELIMITER ;

-- Insert Default Librarian
INSERT INTO Librarian (first_name, last_name, Email, Password) 
VALUES ('Alice', 'Admin', 'librarian@library.com', 'Lib123ab');

-- Insert Sample Books
INSERT INTO Books (ISBN, Title, Author, Price) VALUES
('9780141439518', 'Pride and Prejudice', 'Jane Austen', 15.99),
('9780062315007', 'The Alchemist', 'Paulo Coelho', 14.99),
('9780743273565', 'The Great Gatsby', 'F. Scott Fitzgerald', 10.99),
('9780451524935', '1984', 'George Orwell', 12.50);

-- Insert Sample Member
INSERT INTO Member (Password, First_name, last_name, Email) VALUES
('Pass1234', 'John', 'Doe', 'john@example.com');