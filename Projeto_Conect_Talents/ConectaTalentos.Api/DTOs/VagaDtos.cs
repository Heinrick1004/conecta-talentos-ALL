using System.ComponentModel.DataAnnotations;

namespace ConectaTalentos.Api.DTOs;

public sealed class VagaWriteRequest
{
    [Required(ErrorMessage = "O título da vaga é obrigatório.")]
    [StringLength(150, ErrorMessage = "O título deve ter no máximo 150 caracteres.")]
    public string Titulo { get; set; } = string.Empty;

    [Required(ErrorMessage = "A descrição é obrigatória.")]
    public string Descricao { get; set; } = string.Empty;

    [Required(ErrorMessage = "Os requisitos são obrigatórios.")]
    public string Requisitos { get; set; } = string.Empty;

    [Required(ErrorMessage = "A cidade é obrigatória.")]
    [StringLength(100, ErrorMessage = "A cidade deve ter no máximo 100 caracteres.")]
    public string Cidade { get; set; } = string.Empty;

    [Required(ErrorMessage = "A UF é obrigatória.")]
    [RegularExpression("^[A-Za-z]{2}$", ErrorMessage = "Informe uma UF com duas letras.")]
    public string Uf { get; set; } = string.Empty;

    [Required(ErrorMessage = "A modalidade é obrigatória.")]
    [RegularExpression("^(Presencial|Remoto|Hibrido)$", ErrorMessage = "A modalidade deve ser Presencial, Remoto ou Hibrido.")]
    public string Modalidade { get; set; } = string.Empty;

    [Required(ErrorMessage = "O status é obrigatório.")]
    [RegularExpression("^(Aberta|Encerrada)$", ErrorMessage = "O status deve ser Aberta ou Encerrada.")]
    public string Status { get; set; } = "Aberta";

    [Required(ErrorMessage = "A data de início é obrigatória.")]
    public DateOnly? DataInicio { get; set; }

    [Required(ErrorMessage = "A data de encerramento é obrigatória.")]
    public DateOnly? DataFim { get; set; }
}

public sealed record VagaResponse(
    int Id,
    string Empresa,
    string Titulo,
    string Descricao,
    string Requisitos,
    string Cidade,
    string Uf,
    string Modalidade,
    string Status,
    DateOnly DataInicio,
    DateOnly DataFim,
    DateTime CriadoEm,
    DateTime AtualizadoEm,
    int Candidaturas);

public sealed record VagaResumoDto(
    int Id,
    string Titulo,
    string Cidade,
    string Uf,
    string Modalidade,
    string Status);