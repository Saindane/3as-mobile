class NoticeModel {
  final int     noticeId;
  final String  title;
  final String  body;
  final String? category;
  final String  priority;
  final bool    isActive;
  final int?    createdBy;
  final String? authorName;
  final String  createdAt;

  const NoticeModel({
    required this.noticeId,
    required this.title,
    required this.body,
    this.category,
    required this.priority,
    required this.isActive,
    this.createdBy,
    this.authorName,
    required this.createdAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> j) => NoticeModel(
        noticeId:   j['notice_id']   as int,
        title:      j['title']       as String,
        body:       j['body']        as String,
        category:   j['category']    as String?,
        priority:   j['priority']    as String? ?? 'normal',
        isActive:   j['is_active']   as bool,
        createdBy:  j['created_by']  as int?,
        authorName: j['author_name'] as String?,
        createdAt:  j['created_at']?.toString() ?? '',
      );

  bool get isUrgent => priority == 'urgent';
}
