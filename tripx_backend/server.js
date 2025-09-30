const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const mongoose = require('mongoose');
const path = require('path'); // Import the path module

// --- Import Routes ---
const authRoutes = require('./src/api/routes/auth.routes');
const userRoutes = require('./src/api/routes/user.routes');
const tripRoutes = require('./src/api/routes/trip.routes');
const scheduleRoutes = require('./src/api/routes/schedule.routes');
const packingListRoutes = require('./src/api/routes/packingList.routes');
const expenseRoutes = require('./src/api/routes/expense.routes');
const noteRoutes = require('./src/api/routes/note.routes');
const destinationRoutes = require('./src/api/routes/destination.routes'); // <-- NEW

// Load environment variables from a .env file
dotenv.config();

// Initialize the Express application
const app = express();

// --- Middlewares ---
app.use(cors());
app.use(express.json());

// --- Serve Static Files (for images) ---
app.use('/public', express.static(path.join(__dirname, 'public')));


// --- API Routes ---
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/trips', tripRoutes);
app.use('/api/schedule', scheduleRoutes);
app.use('/api/packing-list', packingListRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/notes', noteRoutes);
app.use('/api/destinations', destinationRoutes); // <-- NEW

// --- Database Connection ---
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB connected successfully.');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
    process.exit(1);
  }
};

// --- Test Route ---
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to the TripX Backend API!' });
});

// --- Start the Server ---
const PORT = process.env.PORT || 5000;

connectDB().then(() => {
    app.listen(PORT, () => {
        console.log(`Server is running on http://localhost:${PORT}`);
    });
});

