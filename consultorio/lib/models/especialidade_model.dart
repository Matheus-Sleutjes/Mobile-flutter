class EspecialidadeModel {
  final String nome;

  EspecialidadeModel({required this.nome});

  factory EspecialidadeModel.fromJson(Map<String, dynamic> json) {
    return EspecialidadeModel(nome: json['nome']);
  }

  Map<String, dynamic> toJson() => {'nome': nome};
} 