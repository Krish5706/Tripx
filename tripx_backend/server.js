const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const mongoose = require('mongoose');
const dns = require('dns');

dotenv.config();

const app = express();

// ======================================================
// Middleware
// ======================================================

app.use(cors());
app.use(express.json());

// ======================================================
// DNS Fix for MongoDB Atlas SRV Issues
// ======================================================

dns.setServers(['8.8.8.8', '8.8.4.4']);

// ======================================================
// MongoDB Configuration
// ======================================================

mongoose.set('bufferCommands', false);

let cachedConnection = false;

const connectDB = async () => {
  try {
    // Already connected
    if (
      cachedConnection ||
      mongoose.connection.readyState === 1
    ) {
      console.log('MongoDB already connected.');
      return;
    }

    // Environment variable check
    if (!process.env.MONGO_URI) {
      throw new Error(
        'MONGO_URI is missing in environment variables'
      );
    }

    console.log('Connecting to MongoDB...');

    await mongoose.connect(process.env.MONGO_URI, {
      family: 4,
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
    });

    cachedConnection = true;

    console.log('MongoDB connected successfully.');
  } catch (error) {
    cachedConnection = false;

    console.error('MongoDB connection failed:');
    console.error(error);
  }
};

// ======================================================
// Database Connection Middleware (Important for Vercel)
// ======================================================

app.use(async (req, res, next) => {
  await connectDB();
  next();
});

// ======================================================
// MongoDB Event Listeners
// ======================================================

mongoose.connection.on('connected', () => {
  console.log('Mongoose connected.');
});

mongoose.connection.on('error', (err) => {
  console.error('Mongoose connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('Mongoose disconnected.');
});

// ======================================================
// Import Routes
// ======================================================

const authRoutes = require('./src/api/routes/auth.routes');
const userRoutes = require('./src/api/routes/user.routes');
const tripRoutes = require('./src/api/routes/trip.routes');
const scheduleRoutes = require('./src/api/routes/schedule.routes');
const packingListRoutes = require('./src/api/routes/packingList.routes');
const expenseRoutes = require('./src/api/routes/expense.routes');
const noteRoutes = require('./src/api/routes/note.routes');
const destinationRoutes = require('./src/api/routes/destination.routes');

// ======================================================
// API Routes
// ======================================================

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/trips', tripRoutes);
app.use('/api/schedule', scheduleRoutes);
app.use('/api/packing-list', packingListRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/notes', noteRoutes);
app.use('/api/destinations', destinationRoutes);

// ======================================================
// Root Route
// ======================================================

app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Welcome to the TripX Backend API!',
    timestamp: new Date().toISOString(),
  });
});

// ======================================================
// Health Check Route
// ======================================================

app.get('/health', async (req, res) => {
  try {
    const state = mongoose.connection.readyState;

    let databaseStatus = 'unknown';

    switch (state) {
      case 0:
        databaseStatus = 'disconnected';
        break;

      case 1:
        databaseStatus = 'connected';
        break;

      case 2:
        databaseStatus = 'connecting';
        break;

      case 3:
        databaseStatus = 'disconnecting';
        break;
    }

    res.status(200).json({
      success: true,
      server: 'running',
      database: databaseStatus,
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ======================================================
// Database Status Route
// ======================================================

app.get('/db-status', async (req, res) => {

  try {

    const state = mongoose.connection.readyState;

    let databaseStatus = 'unknown';

    switch (state) {

      case 0:
        databaseStatus = 'disconnected';
        break;

      case 1:
        databaseStatus = 'connected';
        break;

      case 2:
        databaseStatus = 'connecting';
        break;

      case 3:
        databaseStatus = 'disconnecting';
        break;
    }

    // Fail if not connected
    if (state !== 1) {

      return res.status(500).json({
        success: false,
        database: databaseStatus,
        message: 'MongoDB is NOT connected'
      });

    }

    // Real DB ping
    await mongoose.connection.db.admin().ping();

    res.status(200).json({
      success: true,
      database: databaseStatus,
      message: 'MongoDB connected successfully'
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      database: 'failed',
      error: error.message
    });

  }

});

app.get('/mongo-debug', async (req, res) => {

  try {

    await mongoose.connect(process.env.MONGO_URI, {
      family: 4,
      serverSelectionTimeoutMS: 10000,
    });

    res.json({
      success: true,
      message: 'MongoDB direct connection success'
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      error: error.message,
      fullError: JSON.stringify(error, null, 2)
    });

  }

});

// ======================================================
// 404 Route Handler
// ======================================================

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.originalUrl,
  });
});

// ======================================================
// Global Error Handler
// ======================================================

app.use((err, req, res, next) => {
  console.error('Global Server Error:');
  console.error(err.stack);

  res.status(500).json({
    success: false,
    message: 'Internal Server Error',
    error:
      process.env.NODE_ENV === 'development'
        ? err.message
        : undefined,
  });
});

// ======================================================
// Export App for Vercel
// ======================================================

module.exports = app;