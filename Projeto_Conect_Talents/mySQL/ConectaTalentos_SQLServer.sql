/*
    ConectaTalentos - banco de dados SQL Server
    Execute este script em uma instancia do SQL Server com permissao para criar bancos.
    O banco e criado somente se ainda nao existir. As tabelas e dados de exemplo
    abaixo devem ser executados uma unica vez em um banco vazio.
*/

IF DB_ID(N'ConectaTalentosDB') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [ConectaTalentosDB]');
END;
GO

USE [ConectaTalentosDB];
GO

/* Empresa: conta administrativa da plataforma e proprietaria das vagas. */
CREATE TABLE dbo.Empresa
(
    Id              INT IDENTITY(1,1) NOT NULL,
    NomeFantasia    NVARCHAR(150) NOT NULL,
    RazaoSocial     NVARCHAR(200) NOT NULL,
    CNPJ            CHAR(14) NOT NULL,
    Email           VARCHAR(254) NOT NULL,
    SenhaHash       VARCHAR(255) NOT NULL,
    Telefone        VARCHAR(30) NULL,
    Cidade          NVARCHAR(100) NULL,
    UF              CHAR(2) NULL,
    CriadoEm        DATETIME NOT NULL CONSTRAINT DF_Empresa_CriadoEm DEFAULT (GETDATE()),
    CONSTRAINT PK_Empresa PRIMARY KEY (Id),
    CONSTRAINT UQ_Empresa_CNPJ UNIQUE (CNPJ),
    CONSTRAINT UQ_Empresa_Email UNIQUE (Email)
);
GO

/* Candidato: conta de autenticacao do futuro aplicativo mobile. */
CREATE TABLE dbo.Candidato
(
    Id              INT IDENTITY(1,1) NOT NULL,
    NomeCompleto    NVARCHAR(150) NOT NULL,
    Email           VARCHAR(254) NOT NULL,
    SenhaHash       VARCHAR(255) NOT NULL,
    Telefone        VARCHAR(30) NULL,
    Cidade          NVARCHAR(100) NULL,
    UF              CHAR(2) NULL,
    Habilidades     NVARCHAR(MAX) NULL,
    CriadoEm        DATETIME NOT NULL CONSTRAINT DF_Candidato_CriadoEm DEFAULT (GETDATE()),
    CONSTRAINT PK_Candidato PRIMARY KEY (Id),
    CONSTRAINT UQ_Candidato_Email UNIQUE (Email)
);
GO

/* Vaga: cada registro pertence a uma unica Empresa; o backend deve filtrar pelo EmpresaId autenticado. */
CREATE TABLE dbo.Vaga
(
    Id              INT IDENTITY(1,1) NOT NULL,
    EmpresaId       INT NOT NULL,
    Titulo          NVARCHAR(150) NOT NULL,
    Descricao       NVARCHAR(MAX) NOT NULL,
    Requisitos      NVARCHAR(MAX) NOT NULL,
    Cidade          NVARCHAR(100) NOT NULL,
    UF              CHAR(2) NOT NULL,
    Modalidade      VARCHAR(20) NOT NULL,
    Status          VARCHAR(20) NOT NULL CONSTRAINT DF_Vaga_Status DEFAULT ('Aberta'),
    DataInicio      DATE NOT NULL,
    DataFim         DATE NOT NULL,
    CriadoEm        DATETIME NOT NULL CONSTRAINT DF_Vaga_CriadoEm DEFAULT (GETDATE()),
    AtualizadoEm    DATETIME NOT NULL CONSTRAINT DF_Vaga_AtualizadoEm DEFAULT (GETDATE()),
    CONSTRAINT PK_Vaga PRIMARY KEY (Id),
    CONSTRAINT FK_Vaga_Empresa FOREIGN KEY (EmpresaId)
        REFERENCES dbo.Empresa (Id) ON DELETE NO ACTION,
    CONSTRAINT CK_Vaga_Modalidade CHECK (Modalidade IN ('Presencial', 'Remoto', 'Hibrido')),
    CONSTRAINT CK_Vaga_Status CHECK (Status IN ('Aberta', 'Encerrada')),
    CONSTRAINT CK_Vaga_Periodo CHECK (DataFim >= DataInicio)
);
GO

/* Candidatura: liga candidato e vaga, impedindo candidatura duplicada para a mesma vaga. */
CREATE TABLE dbo.Candidatura
(
    Id              INT IDENTITY(1,1) NOT NULL,
    VagaId          INT NOT NULL,
    CandidatoId     INT NOT NULL,
    Status          VARCHAR(20) NOT NULL CONSTRAINT DF_Candidatura_Status DEFAULT ('Pendente'),
    DataCandidatura DATETIME NOT NULL CONSTRAINT DF_Candidatura_DataCandidatura DEFAULT (GETDATE()),
    AtualizadoEm    DATETIME NOT NULL CONSTRAINT DF_Candidatura_AtualizadoEm DEFAULT (GETDATE()),
    CONSTRAINT PK_Candidatura PRIMARY KEY (Id),
    CONSTRAINT UQ_Candidatura_Vaga_Candidato UNIQUE (VagaId, CandidatoId),
    CONSTRAINT UQ_Candidatura_Id_Candidato UNIQUE (Id, CandidatoId),
    CONSTRAINT FK_Candidatura_Vaga FOREIGN KEY (VagaId)
        REFERENCES dbo.Vaga (Id) ON DELETE CASCADE,
    CONSTRAINT FK_Candidatura_Candidato FOREIGN KEY (CandidatoId)
        REFERENCES dbo.Candidato (Id) ON DELETE CASCADE,
    CONSTRAINT CK_Candidatura_Status CHECK (Status IN ('Pendente', 'Aceita', 'Recusada'))
);
GO

/* Notificacao: mensagens destinadas ao candidato no aplicativo; acompanha a exclusao da candidatura. */
CREATE TABLE dbo.Notificacao
(
    Id              INT IDENTITY(1,1) NOT NULL,
    CandidatoId     INT NOT NULL,
    CandidaturaId   INT NOT NULL,
    Titulo          NVARCHAR(100) NOT NULL,
    Mensagem        NVARCHAR(300) NOT NULL,
    Lida            BIT NOT NULL CONSTRAINT DF_Notificacao_Lida DEFAULT (0),
    CriadoEm        DATETIME NOT NULL CONSTRAINT DF_Notificacao_CriadoEm DEFAULT (GETDATE()),
    CONSTRAINT PK_Notificacao PRIMARY KEY (Id),
    CONSTRAINT FK_Notificacao_Candidato FOREIGN KEY (CandidatoId)
        REFERENCES dbo.Candidato (Id) ON DELETE NO ACTION,
    CONSTRAINT FK_Notificacao_Candidatura_Candidato FOREIGN KEY (CandidaturaId, CandidatoId)
        REFERENCES dbo.Candidatura (Id, CandidatoId) ON DELETE CASCADE
);
GO

/* Indices para as consultas mais frequentes por empresa, vaga, candidato e caixa de notificacoes. */
CREATE INDEX IX_Vaga_EmpresaId ON dbo.Vaga (EmpresaId);
CREATE INDEX IX_Candidatura_VagaId ON dbo.Candidatura (VagaId);
CREATE INDEX IX_Candidatura_CandidatoId ON dbo.Candidatura (CandidatoId);
CREATE INDEX IX_Notificacao_CandidatoId ON dbo.Notificacao (CandidatoId);
GO

/* Atualiza o marcador de sincronizacao sempre que uma vaga for alterada. */
CREATE TRIGGER dbo.TR_Vaga_AtualizarEm
ON dbo.Vaga
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE vaga
       SET AtualizadoEm = GETDATE()
    FROM dbo.Vaga AS vaga
    INNER JOIN inserted AS nova ON nova.Id = vaga.Id;
END;
GO

/* Mantem o horario de sincronizacao e cria aviso quando o status muda para Aceita ou Recusada. */
CREATE TRIGGER dbo.TR_Candidatura_AtualizarENotificar
ON dbo.Candidatura
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* O UPDATE interno do trigger tambem o dispara; esta guarda evita recursao. */
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE candidatura
       SET AtualizadoEm = GETDATE()
    FROM dbo.Candidatura AS candidatura
    INNER JOIN inserted AS nova ON nova.Id = candidatura.Id;

    INSERT INTO dbo.Notificacao (CandidatoId, CandidaturaId, Titulo, Mensagem)
    SELECT
        nova.CandidatoId,
        nova.Id,
        CASE nova.Status
            WHEN 'Aceita' THEN N'Sua candidatura foi aceita'
            ELSE N'Sua candidatura foi recusada'
        END,
        LEFT(CONCAT(
            N'A candidatura para a vaga "', vaga.Titulo,
            N'" foi ', LOWER(nova.Status), N'.'
        ), 300)
    FROM inserted AS nova
    INNER JOIN deleted AS anterior ON anterior.Id = nova.Id
    INNER JOIN dbo.Vaga AS vaga ON vaga.Id = nova.VagaId
    WHERE nova.Status IN ('Aceita', 'Recusada')
      AND nova.Status <> anterior.Status;
END;
GO

/* Dados ficticios para validacao local. Os valores de SenhaHash abaixo sao marcadores,
   nao hashes utilizaveis; substitua-os por hashes BCrypt/Argon2 gerados pela aplicacao. */

INSERT INTO dbo.Empresa (NomeFantasia, RazaoSocial, CNPJ, Email, SenhaHash, Telefone, Cidade, UF)
VALUES
    (N'Empresa X', N'Empresa X Tecnologia Ltda.', '00000000000191', 'contato@empresax.example', 'HASH_DEMO_NAO_USAR', '(15) 3333-1000', N'Sorocaba', 'SP'),
    (N'Empresa Y', N'Empresa Y Servicos Ltda.', '00000000000272', 'contato@empresay.example', 'HASH_DEMO_NAO_USAR', '(11) 3333-2000', N'Sao Paulo', 'SP'),
    (N'Empresa Z', N'Empresa Z Solucoes Ltda.', '00000000000353', 'contato@empresaz.example', 'HASH_DEMO_NAO_USAR', '(19) 3333-3000', N'Campinas', 'SP');
GO

INSERT INTO dbo.Candidato (NomeCompleto, Email, SenhaHash, Telefone, Cidade, UF, Habilidades)
VALUES
    (N'Lucas Ferreira', 'lucas.ferreira@email.com', 'HASH_DEMO_NAO_USAR', '(15) 99912-3410', N'Sorocaba', 'SP', N'C#; .NET; SQL; Git'),
    (N'Juliana Santos', 'juliana.santos@email.com', 'HASH_DEMO_NAO_USAR', '(11) 99876-2345', N'Sao Paulo', 'SP', N'SQL; JavaScript; HTML; CSS'),
    (N'Rafael Oliveira', 'rafael.oliveira@email.com', 'HASH_DEMO_NAO_USAR', '(19) 99123-4567', N'Campinas', 'SP', N'Suporte; Redes; Hardware; Windows'),
    (N'Amanda Lima', 'amanda.lima@email.com', 'HASH_DEMO_NAO_USAR', '(11) 98765-4321', N'Jundiai', 'SP', N'Python; SQL; Logica; Excel'),
    (N'Gabriel Costa', 'gabriel.costa@email.com', 'HASH_DEMO_NAO_USAR', '(11) 97654-3210', N'Sao Paulo', 'SP', N'Figma; Design; Prototipacao; UI/UX');
GO

INSERT INTO dbo.Vaga (EmpresaId, Titulo, Descricao, Requisitos, Cidade, UF, Modalidade, Status, DataInicio, DataFim)
VALUES
    (1, N'Desenvolvedor .NET', N'Buscamos uma pessoa desenvolvedora .NET para construir e evoluir servicos que apoiam as operacoes da empresa.', N'Experiencia com C# e .NET; conhecimento de APIs REST e SQL; familiaridade com Git e testes automatizados.', N'Sorocaba', 'SP', 'Hibrido', 'Aberta', '2026-08-10', '2026-10-31'),
    (1, N'Analista de Sistemas', N'A pessoa analista de sistemas entendera necessidades internas, documentara processos e apoiara a evolucao das solucoes digitais.', N'Levantamento de requisitos; conhecimento de SQL e modelagem de processos; comunicacao clara.', N'São Paulo', 'SP', 'Remoto', 'Aberta', '2026-09-01', '2026-11-15'),
    (1, N'Assistente Administrativo', N'Apoio as rotinas administrativas, organizacao de documentos e atendimento as equipes.', N'Ensino medio completo; organizacao; ferramentas de escritorio; boa comunicacao.', N'Campinas', 'SP', 'Presencial', 'Aberta', '2026-08-15', '2026-12-15'),
    (2, N'Estagiario de TI', N'Oportunidade para aprender com o time de tecnologia e colaborar em suporte, documentacao e melhoria de sistemas.', N'Ensino superior em tecnologia em andamento; logica de programacao e SQL; vontade de aprender.', N'Jundiai', 'SP', 'Hibrido', 'Aberta', '2026-09-10', '2026-12-20'),
    (3, N'Tecnico de Suporte', N'Atendimento tecnico de primeiro nivel, com registro de chamados, diagnostico inicial e acompanhamento.', N'Conhecimentos de hardware, Windows e redes; experiencia com atendimento.', N'Sorocaba', 'SP', 'Presencial', 'Encerrada', '2025-01-15', '2025-04-30');
GO

SET IDENTITY_INSERT dbo.Candidatura ON;
GO

INSERT INTO dbo.Candidatura (Id, VagaId, CandidatoId, Status, DataCandidatura)
VALUES
    (101, 1, 1, 'Pendente', '2026-09-10T09:00:00'),
    (102, 1, 2, 'Pendente', '2026-09-11T10:30:00'),
    (103, 1, 3, 'Aceita', '2026-09-12T14:15:00'),
    (105, 4, 4, 'Recusada', '2026-09-13T08:45:00'),
    (108, 2, 5, 'Pendente', '2026-09-14T16:20:00');
GO

SET IDENTITY_INSERT dbo.Candidatura OFF;
GO

/* Notificacoes de exemplo para candidaturas aceitas/recusadas ja presentes nos dados iniciais. */
INSERT INTO dbo.Notificacao (CandidatoId, CandidaturaId, Titulo, Mensagem, Lida)
VALUES
    (3, 103, N'Sua candidatura foi aceita', N'Sua candidatura para a vaga "Desenvolvedor .NET" foi aceita.', 0),
    (4, 105, N'Sua candidatura foi recusada', N'Sua candidatura para a vaga "Estagiario de TI" foi recusada.', 0),
    (1, 101, N'Candidatura enviada', N'Sua candidatura para a vaga "Desenvolvedor .NET" foi enviada.', 0),
    (2, 102, N'Candidatura enviada', N'Sua candidatura para a vaga "Desenvolvedor .NET" foi enviada.', 0);
GO