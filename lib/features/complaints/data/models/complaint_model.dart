class ComplaintModel {
  final int     complaintId;
  final int?    propertyId;
  final int?    raisedBy;
  final int?    assignedTo;
  final String  category;
  final String  priority;
  final String  status;
  final String  title;
  final String? description;
  final String? resolution;
  final String  createdAt;
  final String  updatedAt;
  final String? unitNo;
  final String? raiserName;

  const ComplaintModel({
    required this.complaintId,
    this.propertyId,
    this.raisedBy,
    this.assignedTo,
    required this.category,
    required this.priority,
    required this.status,
    required this.title,
    this.description,
    this.resolution,
    required this.createdAt,
    required this.updatedAt,
    this.unitNo,
    this.raiserName,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> j) => ComplaintModel(
        complaintId: j['complaint_id'] as int,
        propertyId:  j['property_id']  as int?,
        raisedBy:    j['raised_by']    as int?,
        assignedTo:  j['assigned_to']  as int?,
        category:    j['category']     as String,
        priority:    j['priority']     as String,
        status:      j['status']       as String,
        title:       j['title']        as String,
        description: j['description']  as String?,
        resolution:  j['resolution']   as String?,
        createdAt:   j['created_at']   as String,
        updatedAt:   j['updated_at']   as String,
        unitNo:      j['unit_no']      as String?,
        raiserName:  j['raiser_name']  as String?,
      );

  bool get isOpen     => !['resolved', 'closed'].contains(status);
  bool get isResolved => status == 'resolved' || status == 'closed';
  bool get isNew      => status == 'new';
}
