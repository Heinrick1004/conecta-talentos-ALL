using ConectaTalentos.Api.Data;
using ConectaTalentos.Api.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ConectaTalentos.Api.Controllers;

[Authorize(Roles = "Empresa")]
[Route("api/candidatos")]
public sealed class CandidatosController(ConectaTalentosContext db) : TenantControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CandidatoListaDto>>> Listar(CancellationToken cancellationToken)
    {
        var tenantId = EmpresaId;
        var rows = await db.Candidaturas.AsNoTracking()
            .Where(item => item.Vaga.EmpresaId == tenantId)
            .OrderByDescending(item => item.DataCandidatura)
            .Select(item => new
            {
                item.CandidatoId,
                item.Candidato.NomeCompleto,
                item.Candidato.Email,
                item.Candidato.Telefone,
                item.Candidato.Cidade,
                item.Candidato.UF,
                item.Candidato.Habilidades,
                item.Status,
                Vaga = new VagaResumoDto(
                    item.Vaga.Id,
                    item.Vaga.Titulo,
                    item.Vaga.Cidade,
                    item.Vaga.UF,
                    item.Vaga.Modalidade,
                    item.Vaga.Status)
            })
            .ToListAsync(cancellationToken);

        var candidatos = rows
            .GroupBy(row => row.CandidatoId)
            .Select(group =>
            {
                var latest = group.First();
                return new CandidatoListaDto(
                    latest.CandidatoId,
                    latest.NomeCompleto,
                    latest.Vaga.Titulo,
                    latest.Email,
                    latest.Telefone,
                    latest.Cidade,
                    latest.UF,
                    latest.Habilidades,
                    group.Select(row => new CandidaturaStatusDto(row.Status, row.Vaga)).ToArray());
            })
            .ToList();

        return Ok(candidatos);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<CandidatoPerfilDto>> ObterPerfil(int id, CancellationToken cancellationToken)
    {
        var candidato = await db.Candidatos.AsNoTracking()
            .Where(item => item.Id == id && item.Candidaturas.Any(app => app.Vaga.EmpresaId == EmpresaId))
            .Select(item => new
            {
                item.Id,
                item.NomeCompleto,
                item.Email,
                item.Telefone,
                item.Cidade,
                item.UF,
                item.Habilidades
            })
            .SingleOrDefaultAsync(cancellationToken);
        if (candidato is null) return NotFound(new { erro = "Candidato não encontrado." });

        var candidaturas = await db.Candidaturas.AsNoTracking()
            .Where(item => item.CandidatoId == id && item.Vaga.EmpresaId == EmpresaId)
            .OrderByDescending(item => item.DataCandidatura)
            .Select(item => new CandidaturaCandidatoDto(
                item.Id,
                item.VagaId,
                item.Status,
                item.DataCandidatura,
                new VagaResumoDto(
                    item.Vaga.Id,
                    item.Vaga.Titulo,
                    item.Vaga.Cidade,
                    item.Vaga.UF,
                    item.Vaga.Modalidade,
                    item.Vaga.Status)))
            .ToListAsync(cancellationToken);

        var cargo = candidaturas.FirstOrDefault()?.Vaga.Titulo ?? "Candidato";
        return Ok(new CandidatoPerfilDto(
            candidato.Id,
            candidato.NomeCompleto,
            candidato.Email,
            candidato.Telefone,
            candidato.Cidade,
            candidato.UF,
            candidato.Habilidades,
            cargo,
            candidaturas));
    }
}