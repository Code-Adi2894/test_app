import '../entities.dart';
import '../main.dart';
import '../objectbox.g.dart';

class SiteService {
  static final SiteService _instance = SiteService._internal();
  factory SiteService() => _instance;
  SiteService._internal();

  final siteBox = objectbox.store.box<Site>();

  // Get all sites
  List<Site> getAllSites() {
    return siteBox.getAll();
  }

  // Get site count
  int getSiteCount() {
    return siteBox.count();
  }

  // Create a new site
  Site createSite(String name, {String? address, String? description}) {
    // Check if site with same name already exists
    final query = siteBox.query(Site_.name.equals(name)).build();
    final existingSites = query.find();
    query.close();

    if (existingSites.isNotEmpty) {
      throw Exception('Site with this name already exists');
    }

    // Create new site
    final newSite = Site(
      name: name,
      address: address,
      description: description,
      isSynced: false, // Mark as not synced so it can be synced
      syncStatus: 'pending',
    );

    // Store the site and get the ID
    final siteId = siteBox.put(newSite);
    newSite.id = siteId;
    
    print('Site created successfully with ID: $siteId');
    print('Total sites in database: ${getSiteCount()}');
    
    return newSite;
  }

  // Get site by ID
  Site? getSiteById(int id) {
    return siteBox.get(id);
  }

  // Update site
  void updateSite(Site site) {
    site.updatedAt = DateTime.now();
    siteBox.put(site);
  }

  // Delete site
  void deleteSite(int id) {
    siteBox.remove(id);
  }

  // Get sites for dropdown (returns list of maps with id and name)
  List<Map<String, dynamic>> getSitesForDropdown() {
    final sites = getAllSites();
    return sites.map((site) => {
      'id': site.id,
      'name': site.name,
    }).toList();
  }
}

// Global instance
final siteService = SiteService(); 