// lib/services/destination_ideas_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../config/api_config.dart';
import '../services/db_helper.dart';
import '../services/weather_service.dart';

class DestinationIdea {
  final String id;
  final String name;
  final String country;
  final String category; // single primary category for quick filtering
  final List<String> tags; // richer tags for personalization
  final String bestSeason; // Spring, Summer, Fall, Winter
  final String description;
  final String imageUrl;
  final double? lat;
  final double? lng;
  final String? currentWeather; // short text like "Sunny 28°C"
  final double score; // aggregated score used for ranking
  final bool isSaved; // favorite
  final String? userNotes; // local notes

  DestinationIdea({
    required this.id,
    required this.name,
    required this.country,
    required this.category,
    required this.tags,
    required this.bestSeason,
    required this.description,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.currentWeather,
    required this.score,
    required this.isSaved,
    required this.userNotes,
  });

  DestinationIdea copyWith({
    String? id,
    String? name,
    String? country,
    String? category,
    List<String>? tags,
    String? bestSeason,
    String? description,
    String? imageUrl,
    double? lat,
    double? lng,
    String? currentWeather,
    double? score,
    bool? isSaved,
    String? userNotes,
  }) {
    return DestinationIdea(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      bestSeason: bestSeason ?? this.bestSeason,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      currentWeather: currentWeather ?? this.currentWeather,
      score: score ?? this.score,
      isSaved: isSaved ?? this.isSaved,
      userNotes: userNotes ?? this.userNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'category': category,
      'tags': jsonEncode(tags),
      'best_season': bestSeason,
      'description': description,
      'image_url': imageUrl,
      'lat': lat,
      'lng': lng,
      'current_weather': currentWeather,
      'score': score,
      'is_saved': isSaved ? 1 : 0,
      'user_notes': userNotes,
    };
  }

  static DestinationIdea fromMap(Map<String, dynamic> m) {
    return DestinationIdea(
      id: m['id'] as String,
      name: m['name'] as String,
      country: m['country'] as String,
      category: m['category'] as String? ?? 'General',
      tags: (m['tags'] == null)
          ? const []
          : List<String>.from(jsonDecode(m['tags'] as String)),
      bestSeason: m['best_season'] as String? ?? 'All',
      description: m['description'] as String? ?? '',
      imageUrl: m['image_url'] as String? ?? '',
      lat: (m['lat'] is int) ? (m['lat'] as int).toDouble() : m['lat'] as double?,
      lng: (m['lng'] is int) ? (m['lng'] as int).toDouble() : m['lng'] as double?,
      currentWeather: m['current_weather'] as String?,
      score: (m['score'] is int)
          ? (m['score'] as int).toDouble()
          : (m['score'] as double?) ?? 0.0,
      isSaved: (m['is_saved'] as int? ?? 0) == 1,
      userNotes: m['user_notes'] as String?,
    );
  }
}

class DestinationIdeasService {
  DestinationIdeasService._();
  static final DestinationIdeasService instance = DestinationIdeasService._();

  static const String table = 'destination_ideas';

  Future<Database> _db() async {
    // Works on both FFI (desktop) & mobile
    try {
      return await DatabaseHelper().database;
    } catch (e, st) {
      developer.log('DB open error: $e', stackTrace: st, name: 'DestinationIdeasService');
      rethrow;
    }
  }

  Future<void> ensureTable() async {
    final db = await _db();
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $table (
          id TEXT PRIMARY KEY,
          name TEXT,
          country TEXT,
          category TEXT,
          tags TEXT,
          best_season TEXT,
          description TEXT,
          image_url TEXT,
          lat REAL,
          lng REAL,
          current_weather TEXT,
          score REAL DEFAULT 0,
          is_saved INTEGER DEFAULT 0,
          user_notes TEXT
        );
      ''');
    } catch (e, st) {
      developer.log('DB ensureTable error: $e', stackTrace: st, name: 'DestinationIdeasService');
      rethrow;
    }
  }

  // ---------- Public API ----------

  /// Fetch, enrich, aggregate-score, and cache latest ideas.
  /// If [forceRefresh] is false, returns cached first, then tries soft update.
  Future<List<DestinationIdea>> syncAndGetIdeas({
    bool forceRefresh = false,
    String? userSeason, // e.g., "Winter" in user's location
    List<String> userInterests = const [], // e.g., ["Beach","Cultural"]
    String? userWeather, // e.g., "Cold", "Rainy"
  }) async {
    developer.log('syncAndGetIdeas called', name: 'DestinationIdeasService');
    await ensureTable();
    developer.log('table ensured', name: 'DestinationIdeasService');
    final db = await _db();
    developer.log('db opened', name: 'DestinationIdeasService');

    if (!forceRefresh) {
      try {
        final cached = await db.query(table, orderBy: 'score DESC');
        developer.log('cached: ${cached.length}', name: 'DestinationIdeasService');
        if (cached.isNotEmpty) {
          return cached.map(DestinationIdea.fromMap).toList();
        }
      } catch (e, st) {
        developer.log('DB query error: $e', stackTrace: st, name: 'DestinationIdeasService');
      }
    }

    // 1) Pull seeds from RoadGoat / fallback curated
    final roadGoatSeeds = await _fetchRoadGoatTop();
    final seeds = roadGoatSeeds ?? _fallbackCurated();
    developer.log('Seeds fetched: ${seeds.length}', name: 'DestinationIdeasService');
    if (roadGoatSeeds != null) {
      developer.log('Used RoadGoat API', name: 'DestinationIdeasService');
    } else {
      developer.log('Used fallback curated list', name: 'DestinationIdeasService');
    }

    // 2) Enrich each seed with Wikivoyage description + image (via SerpApi/Tripadvisor) + coords
    final enriched = <DestinationIdea>[];
    for (final base in seeds) {
      final desc = await _fetchWikivoyageSummary(base.name, base.country) ?? base.description;
      final img = await _fetchImage(base.name, base.country) ?? base.imageUrl;
      final coords = await _fetchGeo(base.name, base.country) ?? (base.lat != null ? (base.lat!, base.lng ?? 0) : null);

      // 3) Weather now via Visual Crossing
      String? weatherNow;
      if (coords != null) {
        try {
          final wMap = await WeatherService.getCurrentWeather(coords.$1, coords.$2);
          if (wMap != null) {
            final condition = wMap['condition'] ?? '';
            final temp = wMap['temperature'] != null ? '${wMap['temperature']}°C' : '';
            weatherNow = '$condition $temp'.trim();
          } else {
            weatherNow = null;
          }
        } catch (e, st) {
          developer.log('Weather fetch error: $e', stackTrace: st, name: 'DestinationIdeasService');
          weatherNow = null;
        }
      }

      // 4) score
      final sc = _computeScore(
        tags: base.tags,
        bestSeason: base.bestSeason,
        userSeason: userSeason,
        userInterests: userInterests,
        userWeather: userWeather,
        weatherNow: weatherNow,
      );

      enriched.add(base.copyWith(
        description: desc,
        imageUrl: img,
        lat: coords?.$1,
        lng: coords?.$2,
        currentWeather: weatherNow,
        score: sc,
      ));
    }
    developer.log('Enriched items: ${enriched.length}', name: 'DestinationIdeasService');

    // 5) Upsert into SQLite
    final batch = db.batch();
    for (final d in enriched) {
      batch.insert(
        table,
        d.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    try {
      await batch.commit(noResult: true);
      developer.log('batch committed', name: 'DestinationIdeasService');
    } catch (e, st) {
      developer.log('DB batch commit error: $e', stackTrace: st, name: 'DestinationIdeasService');
    }

    try {
      final rows = await db.query(table, orderBy: 'score DESC');
      final result = rows.map(DestinationIdea.fromMap).toList();
      developer.log('Final cached items: ${result.length}', name: 'DestinationIdeasService');
      return result;
    } catch (e, st) {
      developer.log('DB query error after commit: $e', stackTrace: st, name: 'DestinationIdeasService');
      return [];
    }
  }

  Future<List<DestinationIdea>> getCached({String? query}) async {
    final db = await _db();
    String? where;
    List<Object?> args = [];
    if (query != null && query.trim().isNotEmpty) {
      where = '(name LIKE ? OR country LIKE ?)';
      final like = '%${query.trim()}%';
      args = [like, like];
    }
    final rows = await db.query(
      table,
      where: where,
      whereArgs: args,
      orderBy: 'score DESC',
    );
    return rows.map(DestinationIdea.fromMap).toList();
  }

  Future<void> toggleSave(String id, bool isSaved) async {
    final db = await _db();
    await db.update(
      table,
      {'is_saved': isSaved ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateNotes(String id, String? notes) async {
    final db = await _db();
    await db.update(
      table,
      {'user_notes': notes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> purgeCache() async {
    final db = await _db();
    await db.delete(table);
  }

  // ---------- Filters & Helpers ----------

  List<DestinationIdea> filterSort(
    List<DestinationIdea> items, {
    String search = '',
    String? season, // Spring, Summer, Fall, Winter
    String? weather, // Sunny, Rainy, Snowy, etc.
    List<String> categories = const [],
    List<String> tags = const [],
    bool onlySaved = false,
    bool trendingFirst = true,
  }) {
    Iterable<DestinationIdea> list = items;

    if (search.trim().isNotEmpty) {
      final q = search.toLowerCase().trim();
      list = list.where((d) =>
          d.name.toLowerCase().contains(q) ||
          d.country.toLowerCase().contains(q));
    }
    if (season != null && season.isNotEmpty && season != 'All') {
      list = list.where((d) => d.bestSeason == season || d.bestSeason == 'All');
    }
    if (weather != null && weather.isNotEmpty) {
      list = list.where((d) => (d.currentWeather ?? '').toLowerCase().contains(weather.toLowerCase()));
    }
    if (categories.isNotEmpty) {
      list = list.where((d) => categories.contains(d.category));
    }
    if (tags.isNotEmpty) {
      list = list.where((d) => d.tags.any(tags.contains));
    }
    if (onlySaved) {
      list = list.where((d) => d.isSaved);
    }

    final sorted = list.toList();
    sorted.sort((a, b) {
      if (trendingFirst) {
        final cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
      }
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  double _computeScore({
    required List<String> tags,
    required String bestSeason,
    String? userSeason,
    List<String> userInterests = const [],
    String? userWeather,
    String? weatherNow,
  }) {
    double s = 0;

    // Seasonal match
    if (userSeason != null && userSeason.isNotEmpty) {
      if (bestSeason == userSeason || bestSeason == 'All') s += 20;
    }

    // Interest overlap
    if (userInterests.isNotEmpty) {
      final overlap = tags.where((t) => userInterests.contains(t)).length;
      s += min(20, overlap * 6.0);
    }

    // Weather logic examples
    if (userWeather != null && weatherNow != null) {
      if (userWeather.toLowerCase().contains('cold') &&
          weatherNow.toLowerCase().contains('sun')) {
        s += 15;
      }
      if (userWeather.toLowerCase().contains('rain') &&
          weatherNow.toLowerCase().contains('clear')) {
        s += 10;
      }
    }

    // Baseline popularity (light random to keep variety)
    s += 30 + Random(bestSeason.hashCode ^ tags.join('|').hashCode).nextInt(20);
    return s;
  }

  // ---------- Remote fetchers (safe, minimal, replace with your full endpoints) ----------

  Future<List<DestinationIdea>?> _fetchRoadGoatTop() async {
    final key = APIConfig.roadGoatApiKey; // add to APIConfig if not present
    final secret = APIConfig.roadGoatApiSecret;
    if ((key.isEmpty) || (secret.isEmpty)) return null;

    try {
      final uri = Uri.parse('https://api.roadgoat.com/api/v2/destinations?search=top');
      final res = await http.get(uri, headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$key:$secret'))}',
      });

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);

      // Map minimal fields (adjust to RoadGoat's schema)
      final list = <DestinationIdea>[];
      final items = (data['data'] as List?) ?? [];
      for (final it in items.take(25)) {
        final attrs = it['attributes'] ?? {};
        final name = (attrs['name'] ?? '').toString();
        if (name.isEmpty) continue;

        final id = it['id'].toString();
        final country = (attrs['country'] ?? 'Unknown').toString();
        final cat = _inferCategory(attrs);
        final tags = _inferTags(attrs);

        list.add(DestinationIdea(
          id: id,
          name: name,
          country: country,
          category: cat,
          tags: tags,
          bestSeason: _inferBestSeason(attrs),
          description: (attrs['short_description'] ?? '').toString(),
          imageUrl: _extractImageUrl(attrs),
          lat: (attrs['latitude'] as num?)?.toDouble(),
          lng: (attrs['longitude'] as num?)?.toDouble(),
          currentWeather: null,
          score: 0,
          isSaved: false,
          userNotes: null,
        ));
      }
      return list;
    } catch (e, st) {
      developer.log('RoadGoat fetch error: $e', stackTrace: st, name: 'DestinationIdeasService');
      return null;
    }
  }

  String _inferCategory(Map attrs) {
    final t = ((attrs['tags'] ?? []) as List).map((e) => e.toString().toLowerCase()).toList();
    if (t.any((e) => e.contains('beach'))) return 'Beach';
    if (t.any((e) => e.contains('mount'))) return 'Mountains';
    if (t.any((e) => e.contains('city'))) return 'City';
    if (t.any((e) => e.contains('advent'))) return 'Adventure';
    if (t.any((e) => e.contains('culture') || e.contains('heritage'))) return 'Cultural';
    return 'General';
    }

  List<String> _inferTags(Map attrs) {
    final t = ((attrs['tags'] ?? []) as List).map((e) => e.toString()).toList();
    return t.isEmpty ? ['General'] : t;
  }

  String _inferBestSeason(Map attrs) {
    // You can parse real monthly data if present; keeping a simple default
    return (attrs['best_season'] ?? 'All').toString();
  }

  String _extractImageUrl(Map attrs) {
    final p = attrs['photo'] ?? attrs['image'] ?? {};
    return (p['url'] ?? '').toString();
  }

  Future<String?> _fetchWikivoyageSummary(String city, String country) async {
    final q = Uri.encodeComponent('$city, $country');
    final url = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$q');
    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body);
      return (j['extract'] as String?)?.trim();
    } catch (e, st) {
      developer.log('Wikivoyage fetch error: $e', stackTrace: st, name: 'DestinationIdeasService');
      return null;
    }
  }

  Future<String?> _fetchImage(String city, String country) async {
    // SerpApi or Tripadvisor–for demo fallback to Unsplash if available
    final key = APIConfig.unsplashApiKey;
    if (key.isEmpty) return null;
    final url = Uri.parse('https://api.unsplash.com/search/photos?query=${Uri.encodeComponent("$city $country skyline travel")}&per_page=1');
    try {
      final res = await http.get(url, headers: {'Authorization': 'Client-ID $key'});
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body);
      final first = (j['results'] as List?)?.first;
      return first?['urls']?['regular'] as String?;
    } catch (e, st) {
      developer.log('Image fetch error: $e', stackTrace: st, name: 'DestinationIdeasService');
      return null;
    }
  }

  Future<(double, double)?> _fetchGeo(String city, String country) async {
    // Use Teleport / Nominatim if you prefer; quick fallback using Teleport
    final url = Uri.parse('https://api.teleport.org/api/cities/?search=${Uri.encodeComponent("$city, $country")}&limit=1');
    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body);
      final list = (j['_embedded']?['city:search-results'] as List?) ?? [];
      if (list.isEmpty) return null;
      final href = list.first?['_links']?['city:item']?['href']?.toString();
      if (href == null) return null;
      final res2 = await http.get(Uri.parse(href));
      if (res2.statusCode != 200) return null;
      final d = jsonDecode(res2.body);
      final lat = (d['location']?['latlon']?['latitude'] as num?)?.toDouble();
      final lng = (d['location']?['latlon']?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return (lat, lng);
    } catch (e, st) {
      developer.log('Geo fetch error: $e', stackTrace: st, name: 'DestinationIdeasService');
      return null;
    }
  }

  // Local curated fallback when APIs or keys aren’t available
  List<DestinationIdea> _fallbackCurated() {
    final items = <Map<String, dynamic>>[
      {
        'id': 'bali',
        'name': 'Bali',
        'country': 'Indonesia',
        'category': 'Beach',
        'tags': ['Beach', 'Cultural', 'Wellness'],
        'best_season': 'Summer',
        'desc': 'Island of the Gods—temples, beaches and rice terraces.',
        'img': '',
        'lat': -8.4095,
        'lng': 115.1889
      },
      {
        'id': 'kyoto',
        'name': 'Kyoto',
        'country': 'Japan',
        'category': 'Cultural',
        'tags': ['Cultural', 'Historic', 'City'],
        'best_season': 'Spring',
        'desc': 'Shrines, temples, and cherry blossoms.',
        'img': '',
        'lat': 35.0116,
        'lng': 135.7681
      },
      {
        'id': 'interlaken',
        'name': 'Interlaken',
        'country': 'Switzerland',
        'category': 'Mountains',
        'tags': ['Mountains', 'Adventure', 'Scenic'],
        'best_season': 'Fall',
        'desc': 'Lakes, peaks, paragliding paradise.',
        'img': '',
        'lat': 46.6863,
        'lng': 7.8632
      },
    ];

    return items.map((m) {
      return DestinationIdea(
        id: m['id'],
        name: m['name'],
        country: m['country'],
        category: m['category'],
        tags: List<String>.from(m['tags']),
        bestSeason: m['best_season'],
        description: m['desc'],
        imageUrl: m['img'],
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        currentWeather: null,
        score: 0,
        isSaved: false,
        userNotes: null,
      );
    }).toList();
  }
}
