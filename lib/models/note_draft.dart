class NoteDraft {
  const NoteDraft({
    this.title = '',
    this.courseCode = '',
    this.courseName = '',
    this.content = '',
    this.pickAttachment = false,
  });

  final String title;
  final String courseCode;
  final String courseName;
  final String content;
  final bool pickAttachment;
}
