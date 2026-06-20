import 'package:json_annotation/json_annotation.dart';

/// Converts between the backend's ISO-8601 date strings (Express's default
/// JSON serialization of a JS `Date`) and [DateTime].
class TimestampConverter implements JsonConverter<DateTime, Object?> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is DateTime) return json;
    if (json is String) return DateTime.parse(json);
    return DateTime.now();
  }

  @override
  Object toJson(DateTime object) => object.toIso8601String();
}

/// Same as [TimestampConverter] but nullable, for optional date fields.
class NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    return const TimestampConverter().fromJson(json);
  }

  @override
  Object? toJson(DateTime? object) {
    if (object == null) return null;
    return const TimestampConverter().toJson(object);
  }
}
