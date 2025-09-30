const mongoose = require('mongoose');

const packingListItemSchema = new mongoose.Schema({
  // Link to the specific trip this item belongs to
  trip: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Trip',
    required: true,
  },
  // The user who owns this item
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  // The name of the item, e.g., "Passport"
  itemName: {
    type: String,
    required: [true, 'Please provide an item name.'],
    trim: true,
  },
  // The category for grouping, e.g., "Documents"
  category: {
    type: String,
    required: [true, 'Please provide a category.'],
    trim: true,
    default: 'Miscellaneous',
  },
  // Whether the user has packed this item
  isPacked: {
    type: Boolean,
    default: false,
  },
}, {
  timestamps: true,
});

const PackingListItem = mongoose.model('PackingListItem', packingListItemSchema);

module.exports = PackingListItem;
