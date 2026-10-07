/**
 * ConectaTalentos — Dados fictícios (mock)
 * Substituir por chamadas à API REST no futuro.
 */








const MOCK_TREINAMENTOS_DESTAQUE = [
  {
    id: 1,
    tag: 'Destaque',
    titulo: 'Diversidade e Inclusão no Ambiente de Trabalho',
    texto: 'Conscientização gera respeito.<br>Respeito gera grandes resultados.',
    acao: 'Continuar treinamento'
  },
  {
    id: 2,
    tag: 'Destaque',
    titulo: 'Relações Étnico-Raciais',
    texto: 'Conheça a história e a cultura afro-brasileira<br>e a importância do combate ao racismo.',
    acao: 'Começar treinamento'
  },
  {
    id: 3,
    tag: 'Destaque',
    titulo: 'História e Cultura Indígena',
    texto: 'Valorize os povos originários e conheça<br>sua história, cultura e contribuições para o Brasil.',
    acao: 'Começar treinamento'
  }
];

const MOCK_TREINAMENTOS = [
  {
    id: 1,
    titulo: 'Diversidade e Inclusão',
    descricao: 'Entenda a importância da diversidade no ambiente de trabalho e como promover um espaço mais acolhedor e respeitoso.',
    progresso: 75,
    thumb: 'diversidade'
  },
  {
    id: 2,
    titulo: 'Relações Étnico-Raciais',
    descricao: 'Conheça a história e a cultura afro-brasileira e a importância do combate ao racismo.',
    progresso: 0,
    thumb: 'etnico'
  },
  {
    id: 3,
    titulo: 'História e Cultura Indígena',
    descricao: 'Valorize os povos originários e conheça sua história, cultura e contribuições para o Brasil.',
    progresso: 0,
    thumb: 'indigena'
  },
  {
    id: 4,
    titulo: 'Inclusão no Ambiente Profissional',
    descricao: 'Saiba como criar ambientes mais acessíveis e inclusivos para todos.',
    progresso: 0,
    thumb: 'acessibilidade'
  }
];

const MOCK_PROGRESSO_GERAL = {
  percentual: 25,
  concluido: 1,
  emAndamento: 3,
  naoIniciado: 0
};
