const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const mongoose = require('mongoose');
const dns = require('dns');

dotenv.config();

const requiredEnv = ['MONGO_URI', 'JWT_SECRET', 'JWT_EXPIRES_IN'];
const missingEnv = requiredEnv.filter((key) => !process.env[key]);
if (missingEnv.length) {
  const errorMessage = `Missing required environment variables: ${missingEnv.join(', ')}`;
  console.error(errorMessage);
  throw new Error(errorMessage);
}

const app = express();

// --- MongoDB Connection Fixes ---
// Force Node to use Google DNS (helps with SRV lookups)
dns.setServers(['8.8.8.8', '8.8.4.4']);

// Disable Mongoose buffering (fail fast if connection fails)
mongoose.set('bufferCommands', false);

// --- Middleware ---
app.use(cors());
app.use(express.json());

let isConnected = false;

const connectDB = async () => {
  if (isConnected) return;
  try {
    await mongoose.connect(process.env.MONGO_URI, {
      family: 4, // Force IPv4 to avoid SRV query issues
      serverSelectionTimeoutMS: 10000, // Fail fast if MongoDB not reachable
    });
    isConnected = true;
    console.log('MongoDB connected successfully.');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
    throw error;
  }
};

const mongoConnection = connectDB();

app.use(async (req, res, next) => {
  try {
    await mongoConnection;
    next();
  } catch (error) {
    res.status(500).json({ status: 'fail', message: 'Database connection failed.' });
  }
});

// --- Import Routes ---
const authRoutes = require('./src/api/routes/auth.routes');
const userRoutes = require('./src/api/routes/user.routes');
const tripRoutes = require('./src/api/routes/trip.routes');
const scheduleRoutes = require('./src/api/routes/schedule.routes');
const packingListRoutes = require('./src/api/routes/packingList.routes');
const expenseRoutes = require('./src/api/routes/expense.routes');
const noteRoutes = require('./src/api/routes/note.routes');
const destinationRoutes = require('./src/api/routes/destination.routes');

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

if (require.main === module) {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}

module.exports = app;
