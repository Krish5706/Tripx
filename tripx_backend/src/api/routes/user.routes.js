const express = require('express');
const multer = require('multer');
const userController = require('../../controllers/user.controller');
const authController = require('../../controllers/auth.controller');

// Use memory storage instead of disk
const storage = multer.memoryStorage();
const upload = multer({ storage });

const router = express.Router();

// Protect all routes after this middleware
router.use(authController.protect);

router.get('/me', userController.getMe);

// File is now in memory (req.file.buffer)
router.patch('/updateMe', upload.single('photo'), userController.updateMe);

router.delete('/deleteMe', userController.deleteMe);

module.exports = router;