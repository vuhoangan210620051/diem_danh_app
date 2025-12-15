class AdminAccount {
  final String username;
  final String passwordHash;

  AdminAccount({required this.username, required this.passwordHash});

  Map<String, dynamic> toJson() => {
    "username": username,
    "passwordHash": passwordHash,
  };

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    return AdminAccount(
      username: json["username"],
      passwordHash: json["passwordHash"],
    );
  }
}
