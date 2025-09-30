const mongoose = require('mongoose');

const destinationSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'A destination must have a name.'],
    trim: true,
  },
  country: {
    type: String,
    required: [true, 'A destination must have a country.'],
    trim: true,
  },
  description: {
    type: String,
    required: [true, 'A destination must have a description.'],
    trim: true,
  },
  imageUrl: {
    type: String,
    required: [true, 'A destination must have an image URL.'],
  },
  category: {
    type: [String],
    enum: [
      'Beach', 'Mountains', 'Nature', 'Cultural', 'Historical', 'Wildlife', 
      'Adventure', 'Spiritual', 'Archaeological', 'City', 'Desert', 'Safari', 
      'Lake', 'Scenic', 'Waterfalls', 'Trekking', 'Skiing', 'Nature Walks', 'Hiking'
    ],
    required: [true, 'A destination must have at least one category.'],
  },
  bestSeason: {
    type: [String],
    enum: ['Winter', 'Summer', 'Monsoon', 'Autumn', 'Spring'],
    required: [true, 'Please specify the best season(s) to visit.'],
  },
  isDomestic: {
    type: Boolean,
    default: false,
  },
}, { collection: 'Destination Ideas' });

const Destination = mongoose.model('Destination', destinationSchema);

module.exports = Destination;