# TripX - Travel Planning Application

[![Flutter](https://img.shields.io/badge/Flutter-3.2.3-blue.svg)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-green.svg)](https://www.mongodb.com/)
[![Express.js](https://img.shields.io/badge/Express.js-4.19.2-lightgrey.svg)](https://expressjs.com/)
[![License: ISC](https://img.shields.io/badge/License-ISC-blue.svg)](https://opensource.org/licenses/ISC)

A comprehensive travel planning application built with Flutter for the frontend and Node.js/Express for the backend. TripX helps users plan, organize, and manage their trips with features like itinerary planning, expense tracking, packing lists, and real-time collaboration.

## 🌟 Features

### Core Functionality
- **Trip Planning**: Create and manage detailed trip itineraries
- **Destination Discovery**: Explore and save interesting destinations
- **Schedule Management**: Organize daily activities and timelines
- **Expense Tracking**: Monitor and categorize trip expenses
- **Packing Lists**: Create and manage packing checklists
- **Note Taking**: Keep trip notes and important information
- **Translation**: Real-time speech-to-text and text-to-speech translation

### User Experience
- **Authentication**: Secure user registration and login
- **Profile Management**: User profiles with customizable information
- **Dark/Light Theme**: Adaptive theming for better user experience
- **Cross-Platform**: Available on iOS and Android devices
- **Offline Support**: Core functionality works without internet connection

## 🏗️ Architecture

### Backend Architecture
```
tripx_backend/
├── src/
│   ├── api/           # API routes and endpoints
│   ├── controllers/   # Request handlers
│   ├── models/        # Database schemas
│   ├── middlewares/   # Custom middleware
│   └── config/        # Configuration files
├── public/            # Static files (images)
├── server.js          # Application entry point
└── package.json       # Dependencies and scripts
```

### Frontend Architecture
```
tripx_frontend/
├── lib/
│   ├── api/           # API integration layer
│   ├── models/        # Data models
│   ├── providers/     # State management
│   ├── repositories/  # Data access layer
│   ├── screens/       # UI screens
│   └── utils/         # Utility functions
├── android/           # Android platform files
├── ios/              # iOS platform files
└── pubspec.yaml      # Flutter dependencies
```

## 🚀 Quick Start

### Prerequisites
- **Node.js** (v18 or higher)
- **MongoDB** (Atlas or local instance)
- **Flutter SDK** (v3.2.3 or higher)
- **Git**

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd tripx_backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Configuration**
   Create a `.env` file in the `tripx_backend` directory:
   ```env
   PORT=5000
   MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/tripx
   JWT_SECRET=your-super-secret-jwt-key
   JWT_EXPIRES_IN=90d
   ```

4. **Start the development server**
   ```bash
   npm run dev
   ```

The backend will be available at `http://localhost:5000`

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd tripx_frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration**
   Update the API base URL in `lib/api/api_constants.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_IP_ADDRESS:5000/api';
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 📡 API Documentation

### Base URL
```
http://localhost:5000/api
```

### Authentication Endpoints
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `GET /auth/me` - Get current user profile

### Trip Management
- `GET /trips` - Get all user trips
- `POST /trips` - Create new trip
- `GET /trips/:id` - Get specific trip
- `PUT /trips/:id` - Update trip
- `DELETE /trips/:id` - Delete trip

### Destinations
- `GET /destinations` - Get all destinations
- `POST /destinations` - Create destination
- `GET /destinations/:id` - Get specific destination

### Schedules
- `GET /schedule` - Get trip schedules
- `POST /schedule` - Create schedule item
- `PUT /schedule/:id` - Update schedule item

### Expenses
- `GET /expenses` - Get trip expenses
- `POST /expenses` - Add expense
- `PUT /expenses/:id` - Update expense
- `DELETE /expenses/:id` - Delete expense

### Packing Lists
- `GET /packing-list` - Get packing list items
- `POST /packing-list` - Add packing item
- `PUT /packing-list/:id` - Update packing item
- `DELETE /packing-list/:id` - Remove packing item

### Notes
- `GET /notes` - Get trip notes
- `POST /notes` - Create note
- `PUT /notes/:id` - Update note
- `DELETE /notes/:id` - Delete note

## 🛠️ Technology Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT (jsonwebtoken)
- **Password Hashing**: bcryptjs
- **File Upload**: Multer
- **CORS**: Enabled for cross-origin requests
- **Environment**: dotenv for configuration

### Frontend
- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Provider
- **Networking**: Dio
- **Local Storage**: Shared Preferences, Secure Storage
- **Speech Processing**: speech_to_text, flutter_tts
- **Charts**: fl_chart
- **Image Handling**: cached_network_image, image_picker

### Development Tools
- **Backend**: Nodemon for hot reloading
- **Code Generation**: JSON Serializable
- **Linting**: Flutter Lints

## 📱 Screenshots

*Add screenshots of your application here*

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow the existing code structure and naming conventions
- Write clear, concise commit messages
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting PR

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Express.js community for the robust backend framework
- MongoDB for the flexible database solution
- All contributors and supporters

## 📞 Support

For support, email [your-email@example.com] or create an issue in the repository.

## 🔄 Version History

### v1.0.0
- Initial release
- Core trip planning functionality
- User authentication and profiles
- Basic expense tracking
- Packing list management
- Note-taking capabilities
- Translation features

### Upcoming Features
- [ ] Real-time collaboration
- [ ] Offline trip synchronization
- [ ] Advanced expense analytics
- [ ] Social trip sharing
- [ ] Weather integration
- [ ] Currency conversion
- [ ] Push notifications

---

**Made with ❤️ by the TripX Team**
