const db = require('../config/database');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// --- FITUR REGISTER ---
exports.register = async (req, res) => {
    const { nama, email, password, role } = req.body;

    try {
        // 1. Enkripsi Password (Hashing)
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 2. Simpan ke Database
        const query = 'INSERT INTO users (nama, email, password, role) VALUES (?, ?, ?, ?)';
        // Default role kita set 'pelanggan' jika tidak diisi
        const userRole = role || 'pelanggan'; 

        db.query(query, [nama, email, hashedPassword, userRole], (err, result) => {
            if (err) {
                // Jika email sudah terdaftar (karena di DB kita set UNIQUE)
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(400).json({ message: 'Email sudah terdaftar!' });
                }
                return res.status(500).json({ error: err.message });
            }
            res.status(201).json({ message: 'Register berhasil! Silakan login.' });
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// --- FITUR LOGIN ---
exports.login = (req, res) => {
    const { email, password } = req.body;

    // 1. Cari user berdasarkan email
    const query = 'SELECT * FROM users WHERE email = ?';
    db.query(query, [email], async (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        
        // Jika user tidak ditemukan
        if (results.length === 0) {
            return res.status(404).json({ message: 'Email tidak ditemukan!' });
        }

        const user = results[0];

        // 2. Cek kecocokan password asli dengan password enkripsi di DB
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Password salah!' });
        }

        // 3. Buat Session (JWT Token)
        // Token ini berisi ID dan Role user, dan akan kedaluwarsa dalam 1 hari
        const token = jwt.sign(
            { id: user.id, role: user.role }, 
            process.env.JWT_SECRET, 
            { expiresIn: '1d' }
        );

        // 4. Kirim balasan ke HP (Flutter)
        res.status(200).json({
            message: 'Login berhasil!',
            token: token,
            user: {
                id: user.id,
                nama: user.nama,
                email: user.email,
                role: user.role
            }
        });
    });
};

exports.getProfile = (req, res) => {
    const user_id = req.user.id;

    const query = 'SELECT id, nama, email, role FROM users WHERE id = ?';

    db.query(query, [user_id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });

        if (results.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        res.status(200).json({
            message: 'Berhasil ambil profile',
            user: results[0]
        });
    });
};