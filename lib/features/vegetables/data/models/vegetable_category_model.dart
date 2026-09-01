import '../../domain/entities/vegetable_category.dart';

class VegetableCategoryModel extends VegetableCategory {
  const VegetableCategoryModel({
    required super.id,
    required super.name,
    required super.isActive,
  });

  factory VegetableCategoryModel.fromJson(Map<String, dynamic> json) {
    return VegetableCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {'name': name};
  }

  VegetableCategory toEntity() {
    return VegetableCategory(id: id, name: name, isActive: isActive);
  }
}
