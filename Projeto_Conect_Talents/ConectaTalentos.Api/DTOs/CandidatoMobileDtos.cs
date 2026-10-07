using System.ComponentModel.DataAnnotations;

namespace ConectaTalentos.Api.DTOs;

/// <summary>Dados necessários para registrar uma conta de candidato.</summary>
public sealed class CandidatoRegistroRequest
{
    [Required(ErrorMessage = "O nome completo é obrigatório.")]
    [StringLength(150, ErrorMessage = "O nome completo deve ter no máximo 150 caracteres.")]
    public string NomeCompleto { get; set; } = string.Empty;

    [Required(ErrorMessage = "O e-mail é obrigatório.")]
    [EmailAddress(ErrorMessage = "Informe um e-mail válido.")]
    [StringLength(254, ErrorMessage = "O e-mail deve ter no máximo 254 caracteres.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "A senha é obrigatória.")]
    [MinLength(8, ErrorMessage = "A senha deve ter pelo menos 8 caracteres.")]
    public string Senha { get; set; } = string.Empty;

    [StringLength(30, ErrorMessage = "O telefone deve ter no máximo 30 caracteres.")]
    public string? Telefone { get; set; }

    [StringLength(100, ErrorMessage = "A cidade deve ter no máximo 100 caracteres.")]
    public string? Cidade { get; set; }

    [RegularExpression("^[A-Za-z]{2}$", ErrorMessage = "Informe uma UF com duas letras.")]
    public string? Uf { get; set; }

    public string? Habilidades { get; set; }
}

/// <summary>Credenciais para autenticar um candidato.</summary>
public sealed class CandidatoLoginRequest
{
    [Required(ErrorMessage = "O e-mail é obrigatório.")]
    [EmailAddress(ErrorMessage = "Informe um e-mail válido.")]
    [StringLength(254, ErrorMessage = "O e-mail deve ter no máximo 254 caracteres.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "A senha é obrigatória.")]
    public string Senha { get; set; } = string.Empty;
}

/// <summary>Identidade pública do candidato autenticado.</summary>
public sealed record CandidatoAuthDto(int Id, string NomeCompleto, string Email);

/// <summary>Token e identidade retornados após autenticação do candidato.</summary>
public sealed record CandidatoLoginResponse(string Token, CandidatoAuthDto Candidato);

/// <summary>Dados públicos de uma vaga disponíveis para candidatos.</summary>
public sealed record VagaPublicaDto(
    int Id,
    string Titulo,
    string Descricao,
    string Requisitos,
    string Cidade,
    string Uf,
    string Modalidade,
    DateOnly DataInicio,
    DateOnly DataFim,
    string NomeFantasiaEmpresa,
    bool JaCandidatado);

/// <summary>Identificador da vaga para criar uma candidatura.</summary>
public sealed class CriarCandidaturaRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Informe uma vaga válida.")]
    public int VagaId { get; set; }
}

/// <summary>Vaga resumida associada a uma candidatura do candidato.</summary>
public sealed record VagaCandidatoResumoDto(
    int Id,
    string Titulo,
    string NomeFantasiaEmpresa,
    string Cidade,
    string Uf,
    string Modalidade);

/// <summary>Candidatura pertencente ao candidato autenticado.</summary>
public sealed record CandidaturaCandidatoMobileDto(
    int Id,
    string Status,
    DateTime DataCandidatura,
    DateTime AtualizadoEm,
    VagaCandidatoResumoDto Vaga);

/// <summary>Notificação destinada ao candidato autenticado.</summary>
public sealed record NotificacaoDto(
    int Id,
    string Titulo,
    string Mensagem,
    bool Lida,
    DateTime CriadoEm,
    int CandidaturaId);

/// <summary>Dados privados do perfil do candidato, sem credenciais.</summary>
public sealed record PerfilCandidatoDto(
    int Id,
    string NomeCompleto,
    string Email,
    string? Telefone,
    string? Cidade,
    string? Uf,
    string? Habilidades,
    DateTime CriadoEm);

/// <summary>Campos editáveis do perfil do candidato, sem e-mail ou senha.</summary>
public sealed class AtualizarPerfilCandidatoRequest
{
    [Required(ErrorMessage = "O nome completo é obrigatório.")]
    [StringLength(150, ErrorMessage = "O nome completo deve ter no máximo 150 caracteres.")]
    public string NomeCompleto { get; set; } = string.Empty;

    [StringLength(30, ErrorMessage = "O telefone deve ter no máximo 30 caracteres.")]
    public string? Telefone { get; set; }

    [StringLength(100, ErrorMessage = "A cidade deve ter no máximo 100 caracteres.")]
    public string? Cidade { get; set; }

    [RegularExpression("^[A-Za-z]{2}$", ErrorMessage = "Informe uma UF com duas letras.")]
    public string? Uf { get; set; }

    public string? Habilidades { get; set; }
}