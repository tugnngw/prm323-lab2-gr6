class MajorModel {
  const MajorModel({
    required this.code,
    required this.name,
    this.totalSemesters = 9,
    this.description = '',
  });

  final String code;
  final String name;
  final int totalSemesters;
  final String description;

  factory MajorModel.fromMap(Map<String, dynamic> map) {
    final rawSemesters = map['totalSemesters'] ?? map['semesters'];
    int parsedSemesters = 9;
    if (rawSemesters is num) {
      parsedSemesters = rawSemesters.toInt();
    } else if (rawSemesters is String) {
      parsedSemesters = int.tryParse(rawSemesters) ?? 9;
    }
    return MajorModel(
      code: map['code']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      totalSemesters: parsedSemesters > 0 ? parsedSemesters : 9,
      description: map['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
    'totalSemesters': totalSemesters,
    'description': description,
  };

}

class CourseMaterial {
  const CourseMaterial({
    required this.description,
    this.author = '',
    this.publisher = '',
    this.publishedDate = '',
    this.edition = '',
    this.isbn = '',
    this.isMain = false,
    this.note = '',
  });

  final String description;
  final String author;
  final String publisher;
  final String publishedDate;
  final String edition;
  final String isbn;
  final bool isMain;
  final String note;

  factory CourseMaterial.fromMap(Map<String, dynamic> map) => CourseMaterial(
    description: map['description']?.toString() ?? map['desc']?.toString() ?? '',
    author: map['author']?.toString() ?? '',
    publisher: map['publisher']?.toString() ?? '',
    publishedDate: map['publishedDate']?.toString() ?? '',
    edition: map['edition']?.toString() ?? '',
    isbn: map['isbn']?.toString() ?? '',
    isMain: map['isMain'] == true || (map['isMain']?.toString().toLowerCase() == 'true'),
    note: map['note']?.toString() ?? '',
  );

  Map<String, dynamic> toMap() => {
    'description': description,
    'author': author,
    'publisher': publisher,
    'publishedDate': publishedDate,
    'edition': edition,
    'isbn': isbn,
    'isMain': isMain,
    'note': note,
  };
}

class CourseLearningOutcome {
  const CourseLearningOutcome({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;

  factory CourseLearningOutcome.fromMap(Map<String, dynamic> map) => CourseLearningOutcome(
    name: map['name']?.toString() ?? '',
    description: map['description']?.toString() ?? map['desc']?.toString() ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
  };
}

class CourseLab {
  const CourseLab({
    required this.id,
    required this.title,
    this.deadline = '',
    this.score,
    this.status = 'pending', // 'submitted', 'graded', 'pending'
    this.weight,
    this.category = '',
    this.type = '',
    this.part = '',
    this.completionCriteria = '',
    this.duration = '',
    this.clo = '',
    this.gradingCriteria = '',
    this.note = '',
  });

  final String id;
  final String title;
  final String deadline;
  final double? score;
  final String status;
  final double? weight;
  final String category;
  final String type;
  final String part;
  final String completionCriteria;
  final String duration;
  final String clo;
  final String gradingCriteria;
  final String note;

  factory CourseLab.fromMap(Map<String, dynamic> map) {
    final title = map['title']?.toString() ?? map['name']?.toString() ?? map['category']?.toString() ?? '';
    final category = map['category']?.toString() ?? map['cat']?.toString() ?? '';
    final rawWeight = map['weight'];
    double? parsedWeight;
    if (rawWeight is num) {
      parsedWeight = rawWeight.toDouble();
    } else if (rawWeight is String) {
      final str = rawWeight.replaceAll(RegExp(r'[^0-9.]'), '');
      parsedWeight = double.tryParse(str);
    }
    final rawScore = map['score'];
    double? parsedScore;
    if (rawScore is num) {
      parsedScore = rawScore.toDouble();
    } else if (rawScore is String) {
      parsedScore = double.tryParse(rawScore.trim());
    }

    return CourseLab(
      id: map['id']?.toString() ?? (category.isNotEmpty ? category : title),
      title: title.isNotEmpty ? title : category,
      deadline: map['deadline']?.toString() ?? '',
      score: parsedScore,
      status: map['status']?.toString() ?? 'pending',
      weight: parsedWeight,
      category: category.isNotEmpty ? category : title,
      type: map['type']?.toString() ?? '',
      part: map['part']?.toString() ?? '',
      completionCriteria: map['completionCriteria']?.toString() ?? '',
      duration: map['duration']?.toString() ?? '',
      clo: map['clo']?.toString() ?? '',
      gradingCriteria: map['gradingCriteria']?.toString() ?? map['grading']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'deadline': deadline,
    if (score != null) 'score': score,
    'status': status,
    if (weight != null) 'weight': weight,
    if (category.isNotEmpty) 'category': category,
    if (type.isNotEmpty) 'type': type,
    if (part.isNotEmpty) 'part': part,
    if (completionCriteria.isNotEmpty) 'completionCriteria': completionCriteria,
    if (duration.isNotEmpty) 'duration': duration,
    if (clo.isNotEmpty) 'clo': clo,
    if (gradingCriteria.isNotEmpty) 'gradingCriteria': gradingCriteria,
    if (note.isNotEmpty) 'note': note,
  };
}

class CourseSlot {
  const CourseSlot({
    required this.number,
    this.title = '',
    this.date = '',
    this.room = '',
    this.topic = '',
    this.teachingType = '',
    this.lo = '',
    this.itu = '',
    this.materials = '',
    this.download = '',
    this.tasks = '',
    this.urls = '',
    this.cqs = '',
  });

  final int number;
  final String title;
  final String date;
  final String room;
  final String topic;
  final String teachingType;
  final String lo;
  final String itu;
  final String materials;
  final String download;
  final String tasks;
  final String urls;
  final String cqs;

  String get displayTopic => topic.isNotEmpty ? topic : (title.isNotEmpty ? title : 'Buổi học $number');

  factory CourseSlot.fromMap(Map<String, dynamic> map) {
    final title = map['title']?.toString() ?? '';
    final topic = map['topic']?.toString() ?? '';
    final cqsVal = map['cqs'];
    String cqsStr = '';
    if (cqsVal is List) {
      cqsStr = cqsVal.map((e) => e.toString()).join('\n');
    } else if (cqsVal != null) {
      cqsStr = cqsVal.toString();
    }
    int parseNumber(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return CourseSlot(
      number: parseNumber(map['number'] ?? map['slot']),
      title: title.isNotEmpty ? title : topic,
      date: map['date']?.toString() ?? '',
      room: map['room']?.toString() ?? '',
      topic: topic.isNotEmpty ? topic : title,
      teachingType: map['teachingType']?.toString() ?? '',
      lo: map['lo']?.toString() ?? '',
      itu: map['itu']?.toString() ?? '',
      materials: map['materials']?.toString() ?? '',
      download: map['download']?.toString() ?? '',
      tasks: map['tasks']?.toString() ?? '',
      urls: map['urls']?.toString() ?? '',
      cqs: cqsStr,
    );
  }

  Map<String, dynamic> toMap() => {
    'number': number,
    'title': title,
    'date': date,
    'room': room,
    if (topic.isNotEmpty) 'topic': topic,
    if (teachingType.isNotEmpty) 'teachingType': teachingType,
    if (lo.isNotEmpty) 'lo': lo,
    if (itu.isNotEmpty) 'itu': itu,
    if (materials.isNotEmpty) 'materials': materials,
    if (download.isNotEmpty) 'download': download,
    if (tasks.isNotEmpty) 'tasks': tasks,
    if (urls.isNotEmpty) 'urls': urls,
    if (cqs.isNotEmpty) 'cqs': cqs,
  };
}

class CourseModel {
  const CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.semester,
    required this.major,
    this.prerequisites = const [],
    this.prerequisiteNote = '',
    this.totalSlots = 0,
    this.completedSlots = 0,
    this.currentGrade,
    this.status = 'enrolled',
    this.lecturer = '',
    this.labs = const [],
    this.slots = const [],
    this.overview = '',
    this.studentTasks = '',
    this.tools = '',
    this.degreeLevel = '',
    this.timeAllocation = '',
    this.scoringScale = '',
    this.minAvgMarkToPass = '',
    this.learningTeachingMethod = '',
    this.note = '',
    this.decisionNo = '',
    this.approvedDate = '',
    this.electiveGroups = const [],
    this.learningOutcomes = const [],
    this.courseMaterials = const [],
    this.materialsRaw = '',
    this.losRaw = '',
    this.cqsRaw = '',
  });

  final String id;
  final String code;
  final String name;
  final int credits;
  final int semester;
  final String major;
  final List<String> prerequisites;
  final String prerequisiteNote;
  final int totalSlots;
  final int completedSlots;
  final double? currentGrade;
  final String status;
  final String lecturer;
  final List<CourseLab> labs;
  final List<CourseSlot> slots;
  final String overview;
  final String studentTasks;
  final String tools;
  final String degreeLevel;
  final String timeAllocation;
  final String scoringScale;
  final String minAvgMarkToPass;
  final String learningTeachingMethod;
  final String note;
  final String decisionNo;
  final String approvedDate;
  final List<String> electiveGroups;
  final List<CourseLearningOutcome> learningOutcomes;
  final List<CourseMaterial> courseMaterials;
  final String materialsRaw;
  final String losRaw;
  final String cqsRaw;

  double get progress => totalSlots > 0 ? completedSlots / totalSlots : 0.0;

  static List<CourseSlot> parseMarkdownSchedule(String scheduleMd, {String cqsMd = ''}) {
    if (scheduleMd.trim().isEmpty) return const [];
    final cqs = parseMarkdownCQs(cqsMd);
    final slots = <CourseSlot>[];
    final blocks = scheduleMd.split(RegExp(r'(?=###\s*Slot\s*\d+)', caseSensitive: false));

    for (final block in blocks) {
      final headerMatch = RegExp(r'###\s*Slot\s*(\d+)', caseSensitive: false).firstMatch(block);
      if (headerMatch == null) continue;
      final num = int.tryParse(headerMatch.group(1) ?? '') ?? 0;
      if (num <= 0) continue;

      final topicMatch = RegExp(r'-\s*\*\*Topic:\*\*\s*([^\r\n]+)', caseSensitive: false).firstMatch(block);
      final matMatch = RegExp(r'-\s*\*\*Materials:\*\*\s*([^\r\n]+)', caseSensitive: false).firstMatch(block);
      final tasksMatch = RegExp(r'-\s*\*\*Tasks:\*\*\s*([^\r\n]+)', caseSensitive: false).firstMatch(block);

      final topic = topicMatch?.group(1)?.replaceAll('<br>', ' ').trim() ?? '';
      final materials = matMatch?.group(1)?.replaceAll('<br>', ' ').trim() ?? '';
      final tasks = tasksMatch?.group(1)?.replaceAll('<br>', ' ').trim() ?? '';

      final cq = cqs[num] ?? '';

      slots.add(CourseSlot(
        number: num,
        title: 'Buổi $num: ${topic.isNotEmpty ? topic : "Bài học $num"}',
        topic: topic,
        materials: materials,
        tasks: tasks,
        cqs: cq,
      ));
    }
    slots.sort((a, b) => a.number.compareTo(b.number));
    return slots;
  }

  static Map<int, String> parseMarkdownCQs(String cqsMd) {
    if (cqsMd.trim().isEmpty) return const {};
    final result = <int, String>{};
    final lines = cqsMd.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final match = RegExp(r'-\s*\*\*Slot\s*(\d+)\s*-\s*([^:]+):\*\*\s*(.*)', caseSensitive: false).firstMatch(line);
      if (match != null) {
        final slotNum = int.tryParse(match.group(1) ?? '') ?? 0;
        final name = match.group(2)?.trim() ?? '';
        final desc = match.group(3)?.trim() ?? '';
        if (slotNum > 0) {
          result[slotNum] = name.isNotEmpty ? '$name: $desc' : desc;
        }
      }
    }
    return result;
  }

  static List<CourseLab> parseMarkdownAssessments(String asmMd) {
    if (asmMd.trim().isEmpty) return const [];
    final assessments = <CourseLab>[];
    final blocks = asmMd.split(RegExp(r'(?=###\s+)'));

    for (final block in blocks) {
      final headerMatch = RegExp(r'###\s+([^(]+)(?:\(([^)]+)\))?').firstMatch(block);
      if (headerMatch == null) continue;
      final category = headerMatch.group(1)?.trim() ?? '';
      final weightStr = headerMatch.group(2)?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '';
      final weightNum = double.tryParse(weightStr);

      final durMatch = RegExp(r'-\s*\*\*Thời gian:\*\*\s*([^\r\n]+)').firstMatch(block);
      final critMatch = RegExp(r'-\s*\*\*Hướng dẫn/Tiêu chí:\*\*\s*([^\r\n]+)').firstMatch(block);

      final duration = durMatch?.group(1)?.trim() ?? '';
      final criteria = critMatch?.group(1)?.replaceAll('<br>', ' ').trim() ?? '';

      if (category.isNotEmpty) {
        final id = category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        assessments.add(CourseLab(
          id: id,
          title: category,
          category: category,
          weight: weightNum,
          duration: duration,
          gradingCriteria: criteria,
          status: 'pending',
        ));
      }
    }
    return assessments;
  }

  static List<CourseMaterial> parseMarkdownMaterials(String matMd) {
    if (matMd.trim().isEmpty) return const [];
    final materials = <CourseMaterial>[];
    final items = matMd.split(RegExp(r'(?=-\s*\*\*[^*]+\*\*)'));

    for (final item in items) {
      final titleMatch = RegExp(r'-\s*\*\*([^*]+)\*\*').firstMatch(item);
      if (titleMatch == null) continue;
      final desc = titleMatch.group(1)?.trim() ?? '';
      final authorMatch = RegExp(r'\*Tác giả:\*\s*([^\r\n]+)').firstMatch(item);
      final mainMatch = RegExp(r'\*Giáo trình chính:\*\s*(Có|true|yes)', caseSensitive: false).firstMatch(item);

      if (desc.isNotEmpty) {
        materials.add(CourseMaterial(
          description: desc,
          author: authorMatch?.group(1)?.trim() ?? '',
          isMain: mainMatch != null,
        ));
      }
    }
    return materials;
  }

  static List<CourseLearningOutcome> parseMarkdownLOs(String losMd) {
    if (losMd.trim().isEmpty) return const [];
    final los = <CourseLearningOutcome>[];
    final lines = losMd.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final match = RegExp(r'-\s*\*\*([^*:]+):\*\*\s*(.*)').firstMatch(line);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        final desc = match.group(2)?.trim() ?? '';
        if (name.isNotEmpty || desc.isNotEmpty) {
          los.add(CourseLearningOutcome(name: name, description: desc));
        }
      }
    }
    return los;
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    List<CourseSlot> parsedSlots = [];
    final syllabusMap = map['syllabus'] is Map ? map['syllabus'] as Map : null;
    final rawSlots = map['slots'] ?? syllabusMap?['slots'];
    if (rawSlots is List) {
      for (final slot in rawSlots) {
        if (slot is Map) {
          parsedSlots.add(CourseSlot.fromMap(Map<String, dynamic>.from(slot)));
        }
      }
    } else if (map['schedule'] is String || map['scheduleRaw'] is String) {
      final scheduleStr = (map['schedule'] ?? map['scheduleRaw']).toString();
      final cqsStr = (map['cqs'] ?? map['cqsRaw'])?.toString() ?? '';
      parsedSlots = parseMarkdownSchedule(scheduleStr, cqsMd: cqsStr);
    }

    List<CourseLab> parsedLabs = [];
    final rawLabs = map['labs'] ?? map['assessments'];
    if (rawLabs is List) {
      for (final l in rawLabs) {
        if (l is Map) {
          parsedLabs.add(CourseLab.fromMap(Map<String, dynamic>.from(l)));
        }
      }
    } else if (rawLabs is String) {
      parsedLabs = parseMarkdownAssessments(rawLabs);
    }

    List<CourseLearningOutcome> parsedLOs = [];
    final rawLOs = map['learningOutcomes'] ?? map['los'];
    if (rawLOs is List) {
      for (final lo in rawLOs) {
        if (lo is Map) {
          parsedLOs.add(CourseLearningOutcome.fromMap(Map<String, dynamic>.from(lo)));
        }
      }
    } else if (rawLOs is String) {
      parsedLOs = parseMarkdownLOs(rawLOs);
    }

    List<CourseMaterial> parsedMaterials = [];
    final rawMaterials = map['courseMaterials'] ?? map['materials'];
    if (rawMaterials is List) {
      for (final m in rawMaterials) {
        if (m is Map) {
          parsedMaterials.add(CourseMaterial.fromMap(Map<String, dynamic>.from(m)));
        }
      }
    } else if (rawMaterials is String) {
      parsedMaterials = parseMarkdownMaterials(rawMaterials);
    }

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return CourseModel(
      id: map['id']?.toString() ?? map['code']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      credits: parseInt(map['credits']),
      semester: parseInt(map['semester']),
      major: map['major']?.toString() ?? '',
      prerequisites: (map['prerequisites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      prerequisiteNote: map['prerequisiteNote']?.toString() ?? '',
      totalSlots: parseInt(map['totalSlots'] ?? syllabusMap?['totalSlots']),
      completedSlots: parseInt(map['completedSlots'] ?? syllabusMap?['completedSlots']),
      currentGrade: parseDouble(map['currentGrade']),
      status: map['status']?.toString() ?? 'enrolled',
      lecturer: map['lecturer']?.toString() ?? '',
      overview: map['overview']?.toString() ?? '',
      studentTasks: map['studentTasks']?.toString() ?? '',
      tools: map['tools']?.toString() ?? '',
      degreeLevel: map['degreeLevel']?.toString() ?? '',
      timeAllocation: map['timeAllocation']?.toString() ?? '',
      scoringScale: map['scoringScale']?.toString() ?? '',
      minAvgMarkToPass: map['minAvgMarkToPass']?.toString() ?? '',
      learningTeachingMethod: map['learningTeachingMethod']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      decisionNo: map['decisionNo']?.toString() ?? '',
      approvedDate: map['approvedDate']?.toString() ?? '',
      electiveGroups: (map['electiveGroups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      slots: parsedSlots,
      labs: parsedLabs,
      learningOutcomes: parsedLOs,
      courseMaterials: parsedMaterials,
      materialsRaw: map['materialsRaw']?.toString() ?? (map['materials'] is String ? map['materials'] as String : ''),
      losRaw: map['losRaw']?.toString() ?? (map['los'] is String ? map['los'] as String : ''),
      cqsRaw: map['cqsRaw']?.toString() ?? (map['cqs'] is String ? map['cqs'] as String : ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'code': code,
    'name': name,
    'credits': credits,
    'semester': semester,
    'major': major,
    'prerequisites': prerequisites,
    if (prerequisiteNote.isNotEmpty) 'prerequisiteNote': prerequisiteNote,
    'totalSlots': totalSlots,
    'completedSlots': completedSlots,
    if (currentGrade != null) 'currentGrade': currentGrade,
    'status': status,
    'lecturer': lecturer,
    'labs': labs.map((l) => l.toMap()).toList(),
    'slots': slots.map((slot) => slot.toMap()).toList(),
    'overview': overview,
    if (studentTasks.isNotEmpty) 'studentTasks': studentTasks,
    if (tools.isNotEmpty) 'tools': tools,
    if (degreeLevel.isNotEmpty) 'degreeLevel': degreeLevel,
    if (timeAllocation.isNotEmpty) 'timeAllocation': timeAllocation,
    if (scoringScale.isNotEmpty) 'scoringScale': scoringScale,
    if (minAvgMarkToPass.isNotEmpty) 'minAvgMarkToPass': minAvgMarkToPass,
    if (learningTeachingMethod.isNotEmpty) 'learningTeachingMethod': learningTeachingMethod,
    if (note.isNotEmpty) 'note': note,
    if (decisionNo.isNotEmpty) 'decisionNo': decisionNo,
    if (approvedDate.isNotEmpty) 'approvedDate': approvedDate,
    if (electiveGroups.isNotEmpty) 'electiveGroups': electiveGroups,
    if (learningOutcomes.isNotEmpty)
      'learningOutcomes': learningOutcomes.map((lo) => lo.toMap()).toList(),
    if (courseMaterials.isNotEmpty)
      'courseMaterials': courseMaterials.map((m) => m.toMap()).toList(),
    if (materialsRaw.isNotEmpty) 'materialsRaw': materialsRaw,
    if (losRaw.isNotEmpty) 'losRaw': losRaw,
    if (cqsRaw.isNotEmpty) 'cqsRaw': cqsRaw,
  };
}
