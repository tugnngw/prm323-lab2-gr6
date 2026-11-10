/// Central slot catalog for FPTU class timetables.
///
/// One place to change when the university changes its timetable: the editor
/// and the weekly view both read from here.
///
/// IMPORTANT — [SlotCatalog.sampleDefault] holds SAMPLE times, not verified
/// official FPTU rules. No public, citable FPTU slot→clock table was found
/// while building this (FAP prints the time next to every session instead of
/// publishing a slot table), so the catalog says so out loud ([verified] is
/// false and the UI labels the values as samples). Every saved session stores
/// its own start/end time, so a wrong sample never silently becomes a fact
/// after the user confirms the times once.
class SlotDefinition {
  const SlotDefinition({
    required this.number,
    required this.start,
    required this.end,
  });

  final int number;

  /// 'HH:mm'.
  final String start;

  /// 'HH:mm'.
  final String end;

  String get label => 'Slot $number';
  String get range => '$start – $end';
}

class SlotCatalog {
  const SlotCatalog({
    required this.slots,
    this.verified = false,
    this.sourceNote = '',
  });

  final List<SlotDefinition> slots;

  /// True only when the times come from a citable university document.
  final bool verified;

  /// Human explanation shown in the editor.
  final String sourceNote;

  SlotDefinition? byNumber(int number) {
    for (final slot in slots) {
      if (slot.number == number) return slot;
    }
    return null;
  }

  bool contains(int number) => byNumber(number) != null;

  List<int> get numbers => slots.map((s) => s.number).toList();

  /// Sample catalogue — replace [slots] with official values and set
  /// [verified] to true once an authoritative source exists.
  static const sampleDefault = SlotCatalog(
    verified: false,
    sourceNote:
        'Giờ của từng slot dưới đây là giá trị mẫu để nhập nhanh, '
        'chưa được xác minh là quy định chính thức của FPTU. '
        'Đối chiếu lại với thời khóa biểu trên FAP của bạn rồi chỉnh giờ nếu cần.',
    slots: [
      SlotDefinition(number: 1, start: '07:30', end: '09:00'),
      SlotDefinition(number: 2, start: '09:10', end: '10:40'),
      SlotDefinition(number: 3, start: '10:50', end: '12:20'),
      SlotDefinition(number: 4, start: '12:50', end: '14:20'),
      SlotDefinition(number: 5, start: '14:30', end: '16:00'),
      SlotDefinition(number: 6, start: '16:10', end: '17:40'),
    ],
  );
}
