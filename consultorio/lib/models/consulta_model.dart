import 'user_model.dart';

class ConsultaModel {
  final String paciente;
  final String doutor;
  final DateTime data;
  final String hora;

  ConsultaModel({
    required this.paciente,
    required this.doutor,
    required this.data,
    required this.hora,
  });

  factory ConsultaModel.fromJson(Map<String, dynamic> json) {
    return ConsultaModel(
      paciente: json['paciente'],
      doutor: json['doutor'],
      data: DateTime.parse(json['data']),
      hora: json['hora'],
    );
  }

  Map<String, dynamic> toJson() => {
        'paciente': paciente,
        'doutor': doutor,
        'data': data.toIso8601String(),
        'hora': hora,
      };
} 