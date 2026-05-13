const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const mongoose = require('mongoose');
const path = require('path');

// --- Import Routes ---
const authRoutes = require('./src/api/routes/auth.routes');
const userRoutes = require('./src/api/routes/user.routes');
const tripRoutes = require('./src/api/routes/trip.routes');
const scheduleRoutes = require('./src/api/routes/schedule.routes');
const packingListRoutes = require('./src/api/routes/packingList.routes');
const expenseRoutes = require('./src/api/routes/expense.routes');
const noteRoutes = require('./src/api/routes/note.routes');
const destinationRoutes = require('./src/api/routes/destination.routes');

dotenv.config();

const app = express();

// --- Middleware ---
app.use(cors());
app.use(express.json());

// --- Static Files ---
app.use('/public', express.static(path.join(__dirname, 'public')));

// --- Routes ---
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/trips', tripRoutes);
app.use('/api/schedule', scheduleRoutes);
app.use('/api/packing-list', packingListRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/notes', noteRoutes);
app.use('/api/destinations', destinationRoutes);

// --- Test Route ---
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to the TripX Backend API!' });
});

// --- MongoDB Connection ---
let isConnected = false;

const connectDB = async () => {
  if (isConnected) return;

  try {
    await mongoose.connect(process.env.MONGO_URI);

    isConnected = true;

    console.log('MongoDB connected successfully.');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
  }
};

connectDB();

// IMPORTANT: Export app instead of app.listen()
module.exports = app;