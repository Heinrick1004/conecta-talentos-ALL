using ConectaTalentos.Api.Data;
using ConectaTalentos.Api.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ConectaTalentos.Api.Controllers;

[Authorize(Roles = "Empresa")]
[Route("api")]
public sealed class CandidaturasController(ConectaTalentosContext db) : TenantControllerBase
{
    [HttpGet("vagas/{vagaId:int}/candidaturas")]
    public async Task<ActionResult<IReadOnlyList<CandidaturaResponse>>> ListarPorVaga(int vagaId, CancellationToken cancellationToken)
    {
        var vagaDaEmpresa = await db.Vagas.AsNoTracking()
            .AnyAsync(vaga => vaga.Id == vagaId && vaga.EmpresaId == EmpresaId, cancellationToken);
        if (!vagaDaEmpresa) return NotFound(new { erro = "Vaga não encontrada." });

        var candidaturas = await db.Candidaturas.AsNoTracking()
            .Where(item => item.VagaId == vagaId && item.Vaga.EmpresaId == EmpresaId)
            .OrderByDescending(item => item.DataCandidatura)
            .Select(item => new CandidaturaResponse(
                item.Id,
                item.VagaId,
                item.CandidatoId,
                item.Status,
                item.DataCandidatura,
                item.AtualizadoEm,
                new CandidatoResumoDto(
                    item.Candidato.Id,
                    item.Candidato.NomeCompleto,
                    "Candidato",
                    item.Candidato.Email,
                    item.Candidato.Telefone,
                    item.Candidato.Cidade,
                    item.Candidato.UF,
                    item.Candidato.Habilidades)))
            .ToListAsync(cancellationToken);

        return Ok(candidaturas);
    }

    [HttpPatch("candidaturas/{id:int}/decidir")]
    public async Task<ActionResult<CandidaturaResponse>> Decidir(int id, DecidirCandidaturaRequest request, CancellationToken cancellationToken)
    {
        if (request.Decisao is not ("Aceita" or "Recusada"))
        {
            return BadRequest(new { erro = "A decisão deve ser Aceita ou Recusada." });
        }

        var candidatura = await db.Candidaturas.SingleOrDefaultAsync(
            item => item.Id == id && item.Vaga.EmpresaId == EmpresaId, cancellationToken);
        if (candidatura is null) return NotFound(new { erro = "Candidatura não encontrada." });

        candidatura.Status = request.Decisao;
        await db.SaveChangesAsync(cancellationToken);
        await db.Entry(candidatura).ReloadAsync(cancellationToken);

        var response = await db.Candidaturas.AsNoTracking()
            .Where(item => item.Id == id && item.Vaga.EmpresaId == EmpresaId)
            .Select(item => new CandidaturaResponse(
                item.Id,
                item.VagaId,
                item.CandidatoId,
                item.Status,
                item.DataCandidatura,
                item.AtualizadoEm,
                new CandidatoResumoDto(
                    item.Candidato.Id,
                    item.Candidato.NomeCompleto,
                    "Candidato",
                    item.Candidato.Email,
                    item.Candidato.Telefone,
                    item.Candidato.Cidade,
                    item.Candidato.UF,
                    item.Candidato.Habilidades)))
            .SingleAsync(cancellationToken);

        return Ok(response);
    }
}
