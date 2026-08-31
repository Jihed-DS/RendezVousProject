class ClientAdminItem {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? address;
  final int rendezVousCount;
    ClientAdminItem({
      this.fullName, this.email, this.phone, this.address,
      required this.id, required this.rendezVousCount,
    });

  factory ClientAdminItem.fromJson(Map<String, dynamic> json) {
    return ClientAdminItem(
      id: json['id'] as String,
            fullName: json['fullName'] as String?,
            email: json['email'] as String?,
            phone: json['phone'] as String?,
            address: json['address'] as String?,
            rendezVousCount: json['rendezVousCount'] as int,
    );
  }
}