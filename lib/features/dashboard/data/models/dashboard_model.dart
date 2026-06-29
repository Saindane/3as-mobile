class DashboardStats {
  final int totalUnits;
  final int totalUsers;
  final int activeUsers;
  final int billsPaid;
  final int billsPending;
  final int openComplaints;
  final int unreadNotices;
  final double collectionAmount;
  final double pendingAmount;

  const DashboardStats({
    required this.totalUnits,
    required this.totalUsers,
    required this.activeUsers,
    required this.billsPaid,
    required this.billsPending,
    required this.openComplaints,
    required this.unreadNotices,
    required this.collectionAmount,
    required this.pendingAmount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        totalUnits:       j['total_units']       as int,
        totalUsers:       j['total_users']        as int,
        activeUsers:      j['active_users']       as int,
        billsPaid:        j['bills_paid']         as int,
        billsPending:     j['bills_pending']      as int,
        openComplaints:   j['open_complaints']    as int,
        unreadNotices:    j['unread_notices']     as int,
        collectionAmount: (j['collection_amount'] as num).toDouble(),
        pendingAmount:    (j['pending_amount']    as num).toDouble(),
      );

  /// Fallback empty stats for resident role
  factory DashboardStats.empty() => const DashboardStats(
        totalUnits: 0, totalUsers: 0, activeUsers: 0,
        billsPaid: 0, billsPending: 0, openComplaints: 0,
        unreadNotices: 0, collectionAmount: 0, pendingAmount: 0,
      );
}

class UserProfile {
  final int userId;
  final String name;
  final String mobile;
  final String? email;
  final String role;
  final bool isActive;

  const UserProfile({
    required this.userId,
    required this.name,
    required this.mobile,
    this.email,
    required this.role,
    required this.isActive,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        userId:   j['user_id']   as int,
        name:     j['name']      as String,
        mobile:   j['mobile']    as String,
        email:    j['email']     as String?,
        role:     j['role']      as String,
        isActive: j['is_active'] as bool,
      );
}

class PropertyInfo {
  final int propertyId;
  final String unitNo;
  final int floor;
  final String type;
  final double? areaSqft;

  const PropertyInfo({
    required this.propertyId,
    required this.unitNo,
    required this.floor,
    required this.type,
    this.areaSqft,
  });

  factory PropertyInfo.fromJson(Map<String, dynamic> j) => PropertyInfo(
        propertyId: j['property_id'] as int,
        unitNo:     j['unit_no']     as String,
        floor:      j['floor']       as int,
        type:       j['type']        as String,
        areaSqft:   (j['area_sqft']  as num?)?.toDouble(),
      );
}
