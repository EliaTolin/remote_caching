import 'package:flutter/foundation.dart';

@immutable
class TestData {
  const TestData({required this.name, required this.age});

  factory TestData.fromJson(Map<String, dynamic> json) =>
      TestData(name: json['name'], age: json['age']);
  final String name;
  final int age;

  Map<String, dynamic> toJson() => {'name': name, 'age': age};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestData &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

@immutable
class TestDataNonSerializable {
  const TestDataNonSerializable({required this.name, required this.age});

  final String name;
  final int age;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestData &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

class BadSerializable {
  BadSerializable(this.value);

  factory BadSerializable.fromJson() {
    throw Exception('Deserialization failed!');
  }
  final String value;

  Map<String, dynamic> toJson() {
    throw Exception('Serialization failed!');
  }
}

class GoodSerializable {
  GoodSerializable(this.value);

  factory GoodSerializable.fromJson(Map<String, dynamic> json) {
    return GoodSerializable(json['value'] as String);
  }
  final String value;

  Map<String, dynamic> toJson() => {'value': value};
}
