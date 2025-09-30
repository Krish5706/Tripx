const express = require('express');
const multer = require('multer');
const userController = require('../../controllers/user.controller');
const authController = require('../../controllers/auth.controller');

// --- Multer Configuration for Image Upload ---
// This tells multer to save uploaded files in the 'public/img/users' directory
const upload = multer({ dest: 'public/img/users' });

const router = express.Router();

// Protect all routes after this middleware
router.use(authController.protect);

router.get('/me', userController.getMe);
// Use multer middleware to handle a single file upload from a field named 'photo'
router.patch('/updateMe', upload.single('photo'), userController.updateMe);
router.delete('/deleteMe', userController.deleteMe);

module.exports = router;
