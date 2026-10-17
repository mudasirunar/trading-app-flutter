import '../../models/instrument_model.dart';

/// Centralized smart search and keyword binding engine for instruments.
/// Provides brand aliases, keyword mapping, multi-priority scoring, and ranking.
class InstrumentSearchHelper {
  const InstrumentSearchHelper._();

  /// Comprehensive keyword & brand aliases for institutional equities.
  static const Map<String, List<String>> brandAliases = {
    'GOOGL': ['google', 'alphabet', 'youtube', 'android', 'goog', 'gemini'],
    'AAPL': ['apple', 'iphone', 'ipad', 'mac', 'macbook', 'ios', 'watch'],
    'MSFT': ['microsoft', 'windows', 'azure', 'xbox', 'office'],
    'NVDA': ['nvidia', 'geforce', 'gpu', 'chips', 'ai chips', 'rtx'],
    'AMZN': ['amazon', 'aws', 'prime', 'ecommerce', 'retail'],
    'META': ['meta', 'facebook', 'fb', 'instagram', 'whatsapp', 'threads', 'oculus'],
    'TSLA': ['tesla', 'musk', 'ev', 'model 3', 'model y', 'cybertruck'],
    'BRK.B': ['berkshire', 'hathaway', 'buffett', 'warren buffett'],
    'JPM': ['jpmorgan', 'chase', 'jp morgan', 'bank'],
    'V': ['visa', 'credit card', 'payments'],
    'LLY': ['eli lilly', 'lilly', 'pharma', 'medicine'],
    'JNJ': ['johnson', 'johnson & johnson', 'j&j', 'bandaid', 'tylenol'],
    'XOM': ['exxon', 'mobil', 'exxonmobil', 'oil', 'gas', 'energy'],
    'WMT': ['walmart', 'supercenter', 'retail'],
    'MCD': ['mcdonalds', 'mcdonald', 'burger', 'fast food'],
    'SMSN': ['samsung', 'galaxy', 'korea', 'electronics', 'smartphones', 'fold'],
    'SONY': ['sony', 'playstation', 'ps5', 'ps4', 'bravia', 'gaming', 'walkman'],
    'TTWO': ['rockstar', 'rockstar games', 'gta', 'gta 6', 'gta6', 'grand theft auto', 'red dead', 'take-two', 'ttwo', '2k'],
    'ANTH': ['anthropic', 'claude', 'claude ai', 'claude 5', 'dario amodei', 'ai'],
    'OPAI': ['openai', 'chatgpt', 'chat gpt', 'gpt', 'sam altman', 'dall-e', 'sora', 'ai'],
    'MA': ['mastercard', 'master card', 'credit card', 'payments'],
    'NFLX': ['netflix', 'streaming', 'movies', 'series'],
    'INTC': ['intel', 'core', 'chips', 'semiconductors', 'processors', 'x86'],
    'DIS': ['disney', 'walt disney', 'marvel', 'star wars', 'pixar', 'disney+'],
    'NKE': ['nike', 'shoes', 'sneakers', 'jordan', 'air jordan', 'apparel', 'just do it'],
    'PG': ['procter', 'gamble', 'p&g', 'tide', 'pampers', 'gillette', 'consumer', 'crest', 'oral-b'],
    'KO': ['coca cola', 'coke', 'coca-cola', 'sprite', 'fanta', 'beverages', 'soda'],
    'PEP': ['pepsi', 'pepsico', 'frito lay', 'doritos', 'lays', 'cheetos', 'gatorade', 'quaker', 'beverages'],
    'COIN': ['coinbase', 'crypto', 'bitcoin', 'btc', 'ethereum', 'exchange'],
    'AMD': ['advanced micro devices', 'ryzen', 'radeon', 'processors', 'gpu', 'chips', 'semiconductors'],
  };

  /// Filters and ranks [all] instruments matching [query] and optional [sector].
  static List<InstrumentModel> filterInstruments(
    List<InstrumentModel> all,
    String query, {
    String? sector,
  }) {
    final cleanQuery = query.trim().toLowerCase();

    // 1. Sector filtering
    final sectorFiltered = all.where((instrument) {
      if (sector == null || sector.isEmpty || sector == 'All') return true;
      return instrument.sector.toLowerCase() == sector.toLowerCase();
    }).toList(growable: false);

    // If query is empty, return sorted alphabetically by symbol
    if (cleanQuery.isEmpty) {
      final list = List<InstrumentModel>.from(sectorFiltered);
      list.sort((a, b) => a.symbol.compareTo(b.symbol));
      return list;
    }

    // 2. Multi-priority scoring & keyword ranking
    int calculateScore(InstrumentModel inst) {
      final sym = inst.symbol.toLowerCase();
      final name = inst.name.toLowerCase();
      final exchange = inst.exchange.toLowerCase();
      final instSector = inst.sector.toLowerCase();
      final aliases = brandAliases[inst.symbol] ?? const [];

      // Priority 0: Exact symbol match (e.g. "AAPL")
      if (sym == cleanQuery) return 0;

      // Priority 1: Exact brand alias match (e.g. "coke" for KO, "iphone" for AAPL)
      if (aliases.contains(cleanQuery)) return 1;

      // Priority 2: Symbol starts with query or query starts with symbol
      if (sym.startsWith(cleanQuery) || cleanQuery.startsWith(sym)) return 2;

      // Priority 3: Symbol contains query
      if (sym.contains(cleanQuery)) return 3;

      // Priority 4: Company name starts with query
      if (name.startsWith(cleanQuery)) return 4;

      // Priority 5: Any word in company name starts with query
      final words = name.split(RegExp(r'[\s\-.,&]+'));
      if (words.any((w) => w.startsWith(cleanQuery))) return 5;

      // Priority 6: Any brand alias starts with query or contains query
      if (aliases.any((a) =>
          a.startsWith(cleanQuery) ||
          a.contains(cleanQuery) ||
          cleanQuery.startsWith(a))) {
        return 6;
      }

      // Priority 7: Company name contains query
      if (name.contains(cleanQuery)) return 7;

      // Priority 8: Exchange matches or contains query
      if (exchange.contains(cleanQuery)) return 8;

      // Priority 9: Sector matches or contains query
      if (instSector.contains(cleanQuery)) return 9;

      // No match
      return -1;
    }

    final scored = <MapEntry<InstrumentModel, int>>[];
    for (final inst in sectorFiltered) {
      final score = calculateScore(inst);
      if (score >= 0) {
        scored.add(MapEntry(inst, score));
      }
    }

    // Sort by:
    // 1) Match Score (lower score = higher priority)
    // 2) Alphabetical order by symbol
    scored.sort((a, b) {
      final scoreCompare = a.value.compareTo(b.value);
      if (scoreCompare != 0) return scoreCompare;
      return a.key.symbol.compareTo(b.key.symbol);
    });

    return scored.map((e) => e.key).toList(growable: false);
  }
}
