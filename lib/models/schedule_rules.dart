import 'academic_profile.dart';
import 'slot_catalog.dart';

/// Pure business rules for class sessions: no UI, no persistence.
abstract final class ScheduleRules {
  /// Empty result shared by every valid form (cheap, immutable).
  static const Map<String, String> _empty = {};

  /// Field-level problems keyed by form field name; empty when valid.
  static Map<String, String> validate({
    required String courseCode,
    required String courseName,
    required int? weekday,
    required int? slotNumber,
    required String startTime,
    required String endTime,
    required SlotCatalog catalog,
    String? effectiveStart,
    String? effectiveEnd,
    bool requireName = true,
  }) {
    final errors = <String, String>{};
    if (courseCode.trim().isEmpty) {
      errors['courseCode'] = 'Nhập mã môn, ví dụ PRM323.';
    }
    // Legacy rows never stored a course name; the list-level guard must not
    // block editing them, while the editor still asks for one.
    if (requireName && courseName.trim().isEmpty) {
      errors['courseName'] = 'Nhập tên môn học.';
    }
    if (weekday == null || weekday < 1 || weekday > 7) {
      errors['weekday'] = 'Chọn thứ trong tuần.';
    }
    if (slotNumber != null && !catalog.contains(slotNumber)) {
      errors['slotNumber'] = 'Slot $slotNumber không có trong bảng slot.';
    }
    final start = TimetableEntry.parseClock(startTime);
    final end = TimetableEntry.parseClock(endTime);
    if (start == null) {
      errors['startTime'] = 'Giờ bắt đầu chưa đúng dạng HH:mm.';
    }
    if (end == null) {
      errors['endTime'] = 'Giờ kết thúc chưa đúng dạng HH:mm.';
    }
    if (start != null && end != null && end <= start) {
      errors['endTime'] = 'Giờ kết thúc phải sau giờ bắt đầu.';
    }
    if (!_isDate(effectiveStart)) {
      errors['effectiveStart'] = 'Ngày bắt đầu chưa đúng dạng yyyy-MM-dd.';
    }
    if (!_isDate(effectiveEnd)) {
      errors['effectiveEnd'] = 'Ngày kết thúc chưa đúng dạng yyyy-MM-dd.';
    }
    final from = effectiveStart ?? '';
    final to = effectiveEnd ?? '';
    if (_isDate(from) && _isDate(to) && from.isNotEmpty && to.isNotEmpty &&
        to.compareTo(from) < 0) {
      errors['effectiveEnd'] = 'Ngày kết thúc không được trước ngày bắt đầu.';
    }
    return errors.isEmpty ? _empty : errors;
  }

  /// Sessions that clash with [candidate], any course included. [ignoreId]
  /// excludes the session being edited so it never conflicts with itself.
  static List<ScheduleConflict> conflictsWith(
    TimetableEntry candidate,
    Iterable<TimetableEntry> existing, {
    String? ignoreId,
  }) {
    final ignore = ignoreId ?? candidate.id;
    return [
      for (final other in existing)
        if ((ignore.isEmpty || other.id != ignore) && candidate.overlaps(other))
          ScheduleConflict(first: candidate, second: other),
    ];
  }

  /// Every overlapping pair inside [entries], each pair reported once.
  static List<ScheduleConflict> allConflicts(Iterable<TimetableEntry> entries) {
    final list = entries.toList();
    return [
      for (var i = 0; i < list.length; i++)
        for (var j = i + 1; j < list.length; j++)
          if (list[i].overlaps(list[j]))
            ScheduleConflict(first: list[i], second: list[j]),
    ];
  }

  /// True when the course/session pair already exists (case-insensitive).
  static bool isDuplicate(
    TimetableEntry candidate,
    Iterable<TimetableEntry> existing, {
    String? ignoreId,
  }) {
    final ignore = ignoreId ?? candidate.id;
    return existing.any(
      (e) => (ignore.isEmpty || e.id != ignore) && candidate.sameSessionAs(e),
    );
  }

  static bool _isDate(String? value) =>
      value == null ||
      value.isEmpty ||
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);
}
