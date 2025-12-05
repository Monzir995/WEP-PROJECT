// server.js
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// --- DATABASE CONNECTION ---
require('dotenv').config(); 

const db = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
});

// --- ROUTES ---

// 1. Test Route
app.get('/', (req, res) => {
    res.send('Library Backend is running!');
});

// 2. Register
app.post('/register', (req, res) => {
    const { password, first_name, last_name, email, phone, address } = req.body;
    const sql = `INSERT INTO Member (Password, First_name, last_name, Email, Phone_number, address) VALUES (?, ?, ?, ?, ?, ?)`;
    db.query(sql, [password, first_name, last_name, email, phone, address], (err, result) => {
        if (err) return res.status(500).json({ error: "Registration failed." });
        res.json({ message: "Member registered successfully!" });
    });
});

// 3. Login
app.post('/login', (req, res) => {
    const { email, password } = req.body;
    const sql = 'SELECT * FROM Member WHERE Email = ? AND Password = ?';
    db.query(sql, [email, password], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (results.length > 0) res.json({ message: 'Login successful!', user: results[0] });
        else res.status(401).json({ error: 'Invalid credentials' });
    });
});

// 4. Get Books (Search)
app.get('/books', (req, res) => {
    const search = req.query.q;
    let sql = 'SELECT * FROM Books';
    let params = [];
    if (search) {
        sql += ' WHERE Title LIKE ? OR Author LIKE ?';
        params = [`%${search}%`, `%${search}%`];
    }
    db.query(sql, params, (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        res.json(results);
    });
});

// 5. Borrow
app.post('/borrow', (req, res) => {
    const { book_id, member_id, due_date } = req.body;
    console.log(`📚 Borrowing Book ID: ${book_id} for Member: ${member_id}`); // DEBUG LOG
    
    const sql = `INSERT INTO Loans (Book_ID, Member_ID, Due_date) VALUES (?, ?, ?)`;
    db.query(sql, [book_id, member_id, due_date], (err, result) => {
        if (err) {
            console.error("Borrow Error:", err);
            return res.status(400).json({ error: err.sqlMessage || "Failed to borrow" });
        }
        res.json({ message: "Book borrowed successfully!" });
    });
});

// 6. Return (FIXED & DEBUGGED)
app.post('/return', (req, res) => {
    const { book_id } = req.body;
    console.log(`🔄 Returning Book ID: ${book_id}`); // DEBUG LOG

    // 1. Mark Loan as Returned
    const sqlLoan = `UPDATE Loans SET Return_date = CURRENT_DATE WHERE Book_ID = ? AND Return_date IS NULL`;
    
    db.query(sqlLoan, [book_id], (err, result) => {
        if (err) {
            console.error('Error updating loan:', err);
            return res.status(500).json({ error: "Failed to update loan" });
        }

        if (result.affectedRows === 0) {
            console.log("⚠️ No active loan found for this book.");
            // We continue anyway to ensure the book status is fixed
        }

        // 2. Mark Book as Available
        const sqlBook = `UPDATE Books SET Status = 'Available' WHERE Book_ID = ?`;
        db.query(sqlBook, [book_id], (err2, result2) => {
            if (err2) console.error('Error updating book status:', err2);
            
            console.log("✅ Return processed successfully.");
            res.json({ message: "Book returned successfully!" });
        });
    });
});

// 7. My Loans
app.get('/my-loans', (req, res) => {
    const { member_id } = req.query;
    const sql = `SELECT Loans.LoanID, Books.Title, Loans.Due_date, Loans.fine_amount, Loans.Book_ID 
                 FROM Loans JOIN Books ON Loans.Book_ID = Books.Book_ID 
                 WHERE Loans.Member_ID = ? AND Loans.Return_date IS NULL`;
    db.query(sql, [member_id], (err, results) => {
        if (err) return res.status(500).json({ error: "Failed to fetch loans" });
        res.json(results);
    });
});

// 8. Reserve
app.post('/reserve', (req, res) => {
    const { book_id, member_id } = req.body;
    const sql = `INSERT INTO Reservations (Member_ID, Book_ID) VALUES (?, ?)`;
    db.query(sql, [member_id, book_id], (err, result) => {
        if (err) return res.status(400).json({ error: err.sqlMessage || "Failed to reserve" });
        res.json({ message: "Reservation successful!" });
    });
});

// 9. Admin Login
app.post('/admin/login', (req, res) => {
    const { email, password } = req.body;
    const sql = 'SELECT * FROM Librarian WHERE Email = ? AND Password = ?';
    db.query(sql, [email, password], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (results.length > 0) res.json({ message: 'Admin Login successful!', admin: results[0] });
        else res.status(401).json({ error: 'Invalid credentials' });
    });
});

// 10. Admin: Add Book
app.post('/books', (req, res) => {
    const { isbn, title, author, price } = req.body;
    const sql = 'INSERT INTO Books (ISBN, Title, Author, Price) VALUES (?, ?, ?, ?)';
    db.query(sql, [isbn, title, author, price], (err, result) => {
        if (err) return res.status(500).json({ error: "Failed to add book" });
        res.json({ message: "Book added successfully!" });
    });
});

// 11. Admin: View Loans (Search)
app.get('/all-loans', (req, res) => {
    const search = req.query.q;
    let sql = `SELECT Loans.LoanID, Books.Title, Member.First_name, Member.last_name, Loans.Due_date, Loans.Return_date 
               FROM Loans JOIN Books ON Loans.Book_ID = Books.Book_ID 
               JOIN Member ON Loans.Member_ID = Member.member_ID`;
    let params = [];
    if (search) {
        sql += ` WHERE Books.Title LIKE ? OR Member.First_name LIKE ? OR Member.last_name LIKE ?`;
        params = [`%${search}%`, `%${search}%`, `%${search}%`];
    }
    sql += ` ORDER BY Loans.Due_date ASC`;
    db.query(sql, params, (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        res.json(results);
    });
});

// 12. Admin: Stats
app.get('/admin/stats', (req, res) => {
    const sql = `SELECT (SELECT COUNT(*) FROM Member) AS total_members,
                        (SELECT COUNT(*) FROM Books) AS total_books,
                        (SELECT COUNT(*) FROM Books WHERE Status = 'Available') AS available_books,
                        (SELECT COUNT(*) FROM Loans WHERE Return_date IS NULL) AS active_loans`;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        res.json(results[0]);
    });
});

// --- START ---
app.listen(3000, () => {
    console.log('🚀 FINAL SERVER running on port 3000');

});
