class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String type;
  final String budget;
  final String neighborhood;
  final String description;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.budget = '',
    this.neighborhood = '',
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type,
      'budget': budget,
      'neighborhood': neighborhood,
      'description': description,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      type: map['type'] as String? ?? 'buyer',
      budget: map['budget'] as String? ?? '',
      neighborhood: map['neighborhood'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}
