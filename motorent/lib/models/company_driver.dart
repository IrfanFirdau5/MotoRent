class CompanyDriver {
  final String driverId;
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  final String status; // available, on_job, offline
  final int totalJobs;
  final double rating;
  final bool isActive;

  CompanyDriver({
    required this.driverId,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.status,
    required this.totalJobs,
    required this.rating,
    required this.isActive,
  });

  factory CompanyDriver.fromMap(Map<String, dynamic> data) {
    return CompanyDriver(
      driverId: data['driverId'],
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      licenseNumber: data['licenseNumber'],
      status: data['status'],
      totalJobs: data['totalJobs'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
    );
  }
}
