class PropertyModel {
  const PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priceEtb,
    required this.bedrooms,
    required this.status,
    this.lat,
    this.lng,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priceEtb: json['priceEtb']?.toString() ?? '0',
      bedrooms: json['bedrooms'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      lat: json['lat']?.toString(),
      lng: json['lng']?.toString(),
    );
  }

  final String id;
  final String title;
  final String description;
  final String priceEtb;
  final int bedrooms;
  final String status;
  final String? lat;
  final String? lng;
}
