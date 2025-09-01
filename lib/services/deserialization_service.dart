import '../entities.dart';

DateTime? safeParseDate(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now(); // or DateTime.now() if fallback is acceptable
    }
  }
  return null;
}

class DeserializationService{
  Site siteFromJson(Map<String, dynamic> json){
    final site = Site(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      description: json["description"] ?? '',
      createdAt:safeParseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: safeParseDate(json['updatedAt']) ?? DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      isSynced: json['isSynced'] ?? '',
    );

    // for cases inside site
    if (json['cases'] != null) {
      site.cases.addAll(
        (json['cases'] as List).map((e) => casesFromJson(e as Map<String, dynamic>)),
      );
    }
    return site;
  }

  casesFromJson(Map<String, dynamic> json){
    final cases = Cases(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'],
      description: json["description"] ?? '',
      createdAt: safeParseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: safeParseDate(json['updatedAt']) ?? DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      isSynced: json['isSynced'] ?? '',
      isLiveSyncEnabled: json['isLiveSyncEnabled']
    );

    // for tasks inside case
    if (json['tasks'] != null) {
      cases.tasks.addAll(
        (json['tasks'] as List).map((e) => tasksFromJson(e as Map<String, dynamic>)),
      );
    }

    return cases;
  }

  tasksFromJson(Map<String, dynamic> json){
    final imagesList = (json['images'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    final task = Task(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        description: json["description"] ?? '',
        isCompleted: json["isCompleted"],
        createdAt: safeParseDate(json['createdAt']) ?? DateTime.now(),
        updatedAt: safeParseDate(json['updatedAt']) ?? DateTime.now(),
        createdBy: json['createdBy'] ?? '',
        updatedBy: json['updatedBy'] ?? '',
        isSynced: json['isSynced'] ?? '',
        isLiveSyncEnabled: json['isLiveSyncEnabled'],
        caseId: json['caseId'],
        siteId: json['siteId'],
        images: imagesList
    );
    return task;
    // for tasks inside case
    // if (json['images'] != null) {
    //   task.images.addAll(
    //     List<String>.from(json['images'] as List),
    //   );
    // }
  }
}