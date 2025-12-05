📚 Library Management System

A full-stack web application designed to manage library operations efficiently. This system allows members to browse, borrow, and reserve books, while providing librarians with a powerful dashboard to manage inventory, track loans, and view statistics.

🚀 Features

👤 Member Features

User Authentication: Secure registration and login system.

Book Catalog: Browse all books with search functionality (Title/Author).

Real-time Availability: Instantly see if a book is "Available" or "Borrowed".

Borrowing System: Borrow books with a specific due date.

Reservation System: Reserve books that are currently unavailable (Join the queue).

Personal Dashboard: View active loans, due dates, and calculate fines.

Return Books: Easy one-click return process.

🛡️ Librarian (Admin) Features

Admin Authentication: Secure login for library staff.

Live Statistics Dashboard: View total members, total books, active loans, and available inventory at a glance.

Inventory Management: Add new books to the system easily.

Loan Management: View a comprehensive list of all active loans, including who borrowed which book.

Search System: Filter loans by member name or book title.

🛠️ Tech Stack

Frontend: HTML5, CSS3, JavaScript (Vanilla), Bootstrap 5 (for responsive design).

Backend: Node.js, Express.js.

Database: MySQL (Relational Database).

API: RESTful API architecture.

⚙️ Installation & Setup

Follow these steps to run the project locally.

1. Prerequisites

Node.js installed.

MySQL Server installed and running.

Git installed.

2. Clone the Repository

git clone [https://github.com/YOUR_USERNAME/library-management-system.git](https://github.com/YOUR_USERNAME/library-management-system.git)
cd library-management-system


3. Install Dependencies

npm install


4. Database Setup

Open your MySQL Workbench (or CLI).

Create a new database named library_db.

Run the provided SQL script (found in database/schema.sql or copy the schema below) to create the tables (Member, Books, Loans, Reservations, etc.).

Important: Insert the initial Librarian account:

INSERT INTO Librarian (first_name, last_name, Email, Password) 
VALUES ('Alice', 'Admin', 'librarian@library.com', 'Lib123ab');


5. Environment Configuration

Create a .env file in the root directory.

Add your database credentials:

DB_HOST=localhost
DB_USER=root
DB_PASSWORD=YOUR_MYSQL_PASSWORD
DB_NAME=library_db
PORT=3000


6. Start the Server

node server.js


You should see: 🚀 FINAL SERVER running on port 3000

7. Run the Application

Open index.html in your browser (or use Live Server in VS Code).

🧪 Testing Credentials

Use these credentials to test the different roles:

Role

Email

Password

Librarian (Admin)

librarian@library.com

Lib123ab

Member

(Register a new account)

(Any 8+ char password)

📡 API Endpoints

Method

Endpoint

Description

POST

/register

Register a new member

POST

/login

Member login

POST

/admin/login

Librarian login

GET

/books

Get all books (supports ?q= search)

POST

/borrow

Create a new loan

POST

/return

Return a book

POST

/reserve

Reserve an unavailable book

GET

/my-loans

Get loans for a specific member

GET

/all-loans

Get all active system loans (Admin)

GET

/admin/stats

Get dashboard statistics

📂 Project Structure

/
├── index.html       # The main frontend interface (Single Page Application)
├── server.js        # Node.js Express Server & API Routes
├── package.json     # Project dependencies
├── .env             # Environment variables (not committed)
└── README.md        # Project documentation


🤝 Future Improvements

Implement JWT (JSON Web Tokens) for more secure authentication.

Add email notifications for overdue books.

Integrate a payment gateway for paying fines.

Created for Web Development Course Project - Fall 2025
