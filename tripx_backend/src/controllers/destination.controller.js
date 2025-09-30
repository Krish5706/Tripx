const Destination = require('../models/destination.model');

// Helper function to get the current season in India
const getCurrentSeason = () => {
  const month = new Date().getMonth() + 1; // getMonth() is 0-indexed
  if (month >= 12 || month <= 2) return 'Winter';
  if (month >= 3 && month <= 5) return 'Summer';
  if (month >= 6 && month <= 9) return 'Monsoon';
  return 'Autumn'; // October and November
};

// @desc    Get destination ideas (seasonal, prioritized) or search
// @route   GET /api/destinations
// @access  Public
exports.getDestinationIdeas = async (req, res) => {
  try {
    const { search } = req.query;
    let destinations;

    if (search) {
      // If there's a search query, find matching destinations
      destinations = await Destination.find({
        $or: [
          { name: { $regex: search, $options: 'i' } },
          { country: { $regex: search, $options: 'i' } },
          { category: { $regex: search, $options: 'i' } },
        ],
      });
    } else {
      // If no search query, get seasonal suggestions
      const currentSeason = getCurrentSeason();

      // Fetch domestic (Indian) destinations for the current season
      const domesticDestinations = await Destination.find({
        bestSeason: currentSeason,
        isDomestic: true,
      });

      // Fetch international destinations for the current season
      const internationalDestinations = await Destination.find({
        bestSeason: currentSeason,
        isDomestic: false,
      });

      // Combine them, prioritizing domestic
      destinations = [...domesticDestinations, ...internationalDestinations];
    }

    res.status(200).json({
      status: 'success',
      results: destinations.length,
      data: {
        destinations,
      },
    });
  } catch (error) {
    res.status(500).json({
      status: 'fail',
      message: 'Failed to fetch destination ideas.',
    });
  }
};

// @desc    Create a new destination (Admin only - for populating the DB)
// @route   POST /api/destinations
// @access  Private/Admin
exports.createDestination = async (req, res) => {
    // NOTE: In a real app, you would add admin role-based protection here.
    try {
        const newDestination = await Destination.create(req.body);
        res.status(201).json({
            status: 'success',
            data: {
                destination: newDestination
            }
        });
    } catch (error) {
        res.status(400).json({
            status: 'fail',
            message: error.message
        });
    }
};

