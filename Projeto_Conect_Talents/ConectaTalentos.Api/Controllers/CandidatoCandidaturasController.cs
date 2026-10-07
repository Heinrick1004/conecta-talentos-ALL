using System.Linq.Expressions;
using ConectaTalentos.Api.Data;
using ConectaTalentos.Api.DTOs;
using ConectaTalentos.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace ConectaTalentos.Api.Controllers;

[Authorize(Roles = "Candidato")]
[Route("api/candidato/candidaturas")]
public sealed class CandidatoCandidaturasController(ConectaTalentosContext db) : TenantControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<CandidaturaCandidatoMobileDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<CandidaturaCandidatoMobileDto>>> Listar(
        [FromQuery] DateTime? desde,
        CancellationToken cancellationToken)
    {
        var candidatoId = CandidatoId;
        var query = db.Candidaturas.AsNoTracking()
            .Where(item => item.CandidatoId == candidatoId);

        if (desde.HasValue)
        {
            query = query.Where(item => item.AtualizadoEm > desde.Value);
        }

        var candidaturas = await query
            .OrderByDescending(item => item.DataCandidatura)
            .Select(ToCandidatoDto())
            .ToListAsync(cancellationToken);

        return Ok(candidaturas);
    }

    [HttpPost]
    [ProducesResponseType(typeof(CandidaturaCandidatoMobileDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CandidaturaCandidatoMobileDto>> Criar(
        CriarCandidaturaRequest request,
        CancellationToken cancellationToken)
    {
        var vaga = await db.Vagas.AsNoTracking()
            .SingleOrDefaultAsync(item => item.Id == request.VagaId, cancellationToken);
        if (vaga is null)
        {
            return NotFound(new { erro = "Vaga não encontrada" });
        }

        if (vaga.Status != "Aberta")
        {
            return BadRequest(new { erro = "Esta vaga não está mais aceitando candidaturas" });
        }

        var candidatoId = CandidatoId;
        if (await db.Candidaturas.AnyAsync(
                item => item.CandidatoId == candidatoId && item.VagaId == request.VagaId,
                cancellationToken))
        {
            return Conflict(new { erro = "Você já se candidatou a esta vaga" });
        }

        var candidatura = new Candidatura
        {
            VagaId = request.VagaId,
            CandidatoId = candidatoId,
            Status = "Pendente",
            DataCandidatura = DateTime.Now
        };

        db.Candidaturas.Add(candidatura);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException exception) when (IsUniqueConstraintViolation(exception))
        {
            return Conflict(new { erro = "Você já se candidatou a esta vaga" });
        }

        var response = await db.Candidaturas.AsNoTracking()
            .Where(item => item.Id == candidatura.Id && item.CandidatoId == candidatoId)
            .Select(ToCandidatoDto())
            .SingleAsync(cancellationToken);

        return CreatedAtAction(nameof(Listar), new { }, response);
    }

    private static Expression<Func<Candidatura, CandidaturaCandidatoMobileDto>> ToCandidatoDto()
    {
        return item => new CandidaturaCandidatoMobileDto(
            item.Id,
            item.Status,
            item.DataCandidatura,
            item.AtualizadoEm,
            new VagaCandidatoResumoDto(
                item.Vaga.Id,
                item.Vaga.Titulo,
                item.Vaga.Empresa.NomeFantasia,
                item.Vaga.Cidade,
                item.Vaga.UF,
                item.Vaga.Modalidade));
    }

    private static bool IsUniqueConstraintViolation(Exception exception)
    {
        return exception.GetBaseException() is SqlException { Number: 2601 or 2627 };
    }
}