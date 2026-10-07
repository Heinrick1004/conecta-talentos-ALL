import 'package:flutter/material.dart';

/// Informações locais usadas para preencher o perfil do candidato.
class PerfilMock {
  const PerfilMock({
    required this.tipo,
    required this.bio,
    required this.candidaturas,
    required this.treinamentos,
    required this.certificados,
  });

  final String tipo;
  final String bio;
  final int candidaturas;
  final int treinamentos;
  final int certificados;
}

class PerfilEstatisticaMock {
  const PerfilEstatisticaMock({
    required this.valor,
    required this.rotulo,
    required this.icone,
  });

  final int valor;
  final String rotulo;
  final IconData icone;
}

class PerfilMenuMock {
  const PerfilMenuMock({
    required this.titulo,
    required this.descricao,
    required this.icone,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
}

const mockPerfil = PerfilMock(
  tipo: 'Candidato',
  bio: 'Em busca de novas oportunidades.',
  candidaturas: 4,
  treinamentos: 2,
  certificados: 1,
);

const mockPerfilEstatisticas = <PerfilEstatisticaMock>[
  PerfilEstatisticaMock(
    valor: 4,
    rotulo: 'Candidaturas',
    icone: Icons.work_outline_rounded,
  ),
  PerfilEstatisticaMock(
    valor: 2,
    rotulo: 'Treinamentos',
    icone: Icons.school_outlined,
  ),
  PerfilEstatisticaMock(
    valor: 1,
    rotulo: 'Certificados',
    icone: Icons.workspace_premium_outlined,
  ),
];

const mockPerfilMenu = <PerfilMenuMock>[
  PerfilMenuMock(
    titulo: 'Meu currículo',
    descricao: 'Visualize e edite suas informações.',
    icone: Icons.description_outlined,
  ),
  PerfilMenuMock(
    titulo: 'Meus interesses',
    descricao: 'Defina as áreas e vagas que te interessam.',
    icone: Icons.favorite_border_rounded,
  ),
  PerfilMenuMock(
    titulo: 'Notificações',
    descricao: 'Acompanhe novidades e atualizações.',
    icone: Icons.notifications_none_rounded,
  ),
  PerfilMenuMock(
    titulo: 'Configurações',
    descricao: 'Ajuste sua conta e preferências.',
    icone: Icons.settings_outlined,
  ),
];
