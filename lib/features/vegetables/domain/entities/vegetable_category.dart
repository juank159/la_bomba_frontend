import 'package:equatable/equatable.dart';

/// A category in the vegetables catalog (e.g. "Verduras", "Frutas"),
/// managed independently from the products themselves.
class VegetableCategory extends Equatable {
  final String id;
  final String name;
  final bool isActive;

  const VegetableCategory({
    required this.id,
    required this.name,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, isActive];

  VegetableCategory copyWith({String? id, String? name, bool? isActive}) {
    return VegetableCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }
}
