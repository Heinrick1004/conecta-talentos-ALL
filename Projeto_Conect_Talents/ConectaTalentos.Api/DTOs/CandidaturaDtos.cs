using System.ComponentModel.DataAnnotations;

namespace ConectaTalentos.Api.DTOs;

public sealed class DecidirCandidaturaRequest
{
    [Required(ErrorMessage = "A decisão é obrigatória.")]
    [RegularExpression("^(Aceita|Recusada)$", ErrorMessage = "A decisão deve ser Aceita ou Recusada.")]
    public string Decisao { get; set; } = string.Empty;
}

public sealed record CandidatoResumoDto(
    int Id,
    string NomeCompleto,
    string? Cargo,
    string Email,
    string? Telefone,
    string? Cidade,
    string? Uf,
    string? Habilidades);

public sealed record CandidaturaResponse(
    int Id,
    int VagaId,
    int CandidatoId,
    string Status,
    DateTime DataCandidatura,
    DateTime AtualizadoEm,
    CandidatoResumoDto Candidato);

public sealed record CandidaturaCandidatoDto(
    int Id,
    int VagaId,
    string Status,
    DateTime DataCandidatura,
    VagaResumoDto Vaga);

public sealed record CandidaturaStatusDto(string Status, VagaResumoDto Vaga);