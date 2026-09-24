class DashboardCardModel {
  final String code;
  final String title;
  final String description;
  final String route;

  const DashboardCardModel({
    required this.code,
    required this.title,
    required this.description,
    required this.route,
  });

  factory DashboardCardModel.fromJson(Map<String, dynamic> json) {
    return DashboardCardModel(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? 'Dashboard',
      description: json['description'] as String? ?? '',
      route: json['route'] as String? ?? '',
    );
  }
}

class DashboardMenuModel {
  final int? id;
  final String code;
  final String title;
  final String? url;
  final String? icon;
  final List<DashboardMenuModel> children;

  const DashboardMenuModel({
    this.id,
    required this.code,
    required this.title,
    this.url,
    this.icon,
    this.children = const [],
  });

  factory DashboardMenuModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>? ?? const [];
    return DashboardMenuModel(
      id: json['id'] as int?,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? 'Menu',
      url: json['url'] as String?,
      icon: json['icon'] as String?,
      children: rawChildren
          .whereType<Map<String, dynamic>>()
          .map(DashboardMenuModel.fromJson)
          .toList(),
    );
  }
}

class DashboardData {
  final List<DashboardCardModel> dashboards;
  final List<DashboardMenuModel> menus;
  final Map<String,dynamic> metrics;

  const DashboardData({this.dashboards = const [], this.menus = const [], this.metrics = const {}});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final rawDashboards = json['dashboards'] as List<dynamic>? ?? const [];
    final rawMenus = json['menus'] as List<dynamic>? ?? const [];
    final metrics = json['metrics'] is Map ? Map<String,dynamic>.from(json['metrics']) : <String,dynamic>{};
    return DashboardData(
      dashboards: rawDashboards
          .whereType<Map<String, dynamic>>()
          .map(DashboardCardModel.fromJson)
          .toList(),
      menus: rawMenus
          .whereType<Map<String, dynamic>>()
          .map(DashboardMenuModel.fromJson)
          .toList(),
      metrics: metrics,
    );
  }
}
