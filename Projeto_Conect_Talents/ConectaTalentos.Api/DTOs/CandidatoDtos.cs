namespace ConectaTalentos.Api.DTOs;

public sealed record CandidatoListaDto(
    int Id,
    string NomeCompleto,
    string Cargo,
    string Email,
    string? Telefone,
    string? Cidade,
    string? Uf,
    string? Habilidades,
    IReadOnlyList<CandidaturaStatusDto> Candidaturas);

public sealed record CandidatoPerfilDto(
    int Id,
    string NomeCompleto,
    string Email,
    string? Telefone,
    string? Cidade,
    string? Uf,
    string? Habilidades,
    string Cargo,
    IReadOnlyList<CandidaturaCandidatoDto> Candidaturas);