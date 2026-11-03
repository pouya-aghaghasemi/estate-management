class PropertyModel {
  final String id;
  final String title;
  final String propertyType;
  final String neighborhood;
  final String area;
  final String bedrooms;
  final String yearBuilt;
  final String floor;
  final String price;
  final bool elevator;
  final bool parking;
  final bool storage;
  final String description;
  final List<String> imagePaths;
  final bool isActive;
  final DateTime createdAt;

  const PropertyModel({
    required this.id,
    required this.title,
    required this.propertyType,
    required this.neighborhood,
    required this.area,
    required this.bedrooms,
    required this.yearBuilt,
    required this.floor,
    required this.price,
    required this.elevator,
    required this.parking,
    required this.storage,
    required this.description,
    this.imagePaths = const [],
    this.isActive = true,
    required this.createdAt,
  });

  // تبدیل مدل به Map برای ذخیره‌سازی
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'propertyType': propertyType,
      'dealType': 'sale',
      'neighborhood': neighborhood,
      'area': area,
      'bedrooms': bedrooms,
      'yearBuilt': yearBuilt,
      'floor': floor,
      'price': price,
      'elevator': elevator,
      'parking': parking,
      'storage': storage,
      'description': description,
      'imagePaths': imagePaths,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ساخت مدل از اطلاعات ذخیره‌شده
  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      propertyType: map['propertyType']?.toString() ?? 'آپارتمان',
      neighborhood: map['neighborhood']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      bedrooms: map['bedrooms']?.toString() ?? '',
      yearBuilt: map['yearBuilt']?.toString() ?? '',
      floor: map['floor']?.toString() ?? '',
      price: map['price']?.toString() ?? '',
      elevator: map['elevator'] as bool? ?? false,
      parking: map['parking'] as bool? ?? false,
      storage: map['storage'] as bool? ?? false,
      description: map['description']?.toString() ?? '',
      imagePaths:
          (map['imagePaths'] as List<dynamic>?)
              ?.map((path) => path.toString())
              .toList() ??
          [],
      isActive: map['isActive'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  // ساخت نسخه جدید از مدل برای ویرایش اطلاعات
  PropertyModel copyWith({
    String? title,
    String? propertyType,
    String? neighborhood,
    String? area,
    String? bedrooms,
    String? yearBuilt,
    String? floor,
    String? price,
    bool? elevator,
    bool? parking,
    bool? storage,
    String? description,
    List<String>? imagePaths,
    bool? isActive,
  }) {
    return PropertyModel(
      id: id,
      title: title ?? this.title,
      propertyType: propertyType ?? this.propertyType,
      neighborhood: neighborhood ?? this.neighborhood,
      area: area ?? this.area,
      bedrooms: bedrooms ?? this.bedrooms,
      yearBuilt: yearBuilt ?? this.yearBuilt,
      floor: floor ?? this.floor,
      price: price ?? this.price,
      elevator: elevator ?? this.elevator,
      parking: parking ?? this.parking,
      storage: storage ?? this.storage,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
