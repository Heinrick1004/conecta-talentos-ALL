using ConectaTalentos.Api.Data;
using ConectaTalentos.Api.DTOs;
using ConectaTalentos.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace ConectaTalentos.Api.Controllers;

[Authorize(Roles = "Candidato")]
[Route("api/candidato/favoritos")]
public sealed class CandidatoFavoritosController(ConectaTalentosContext db) : TenantControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<VagaPublicaDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<VagaPublicaDto>>> Listar(
        CancellationToken cancellationToken)
    {
        var candidatoId = CandidatoId;
        var favoritos = await db.Favoritos.AsNoTracking()
            .Where(favorito => favorito.CandidatoId == candidatoId)
            .OrderByDescending(favorito => favorito.CriadoEm)
            .Select(favorito => new VagaPublicaDto(
                favorito.Vaga.Id,
                favorito.Vaga.Titulo,
                favorito.Vaga.Descricao,
                favorito.Vaga.Requisitos,
                favorito.Vaga.Cidade,
                favorito.Vaga.UF,
                favorito.Vaga.Modalidade,
                favorito.Vaga.DataInicio,
                favorito.Vaga.DataFim,
                favorito.Vaga.Empresa.NomeFantasia,
                favorito.Vaga.Candidaturas.Any(candidatura =>
                    candidatura.CandidatoId == candidatoId),
                true))
            .ToListAsync(cancellationToken);

        return Ok(favoritos);
    }

    [HttpPost("{vagaId:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Adicionar(
        int vagaId,
        CancellationToken cancellationToken)
    {
        var candidatoId = CandidatoId;
        var vagaExiste = await db.Vagas.AsNoTracking()
            .AnyAsync(vaga => vaga.Id == vagaId, cancellationToken);
        if (!vagaExiste)
        {
            return NotFound(new { erro = "Vaga não encontrada." });
        }

        var jaFavoritada = await db.Favoritos.AsNoTracking()
            .AnyAsync(favorito =>
                favorito.CandidatoId == candidatoId && favorito.VagaId == vagaId,
                cancellationToken);
        if (jaFavoritada)
        {
            return NoContent();
        }

        db.Favoritos.Add(new Favorito
        {
            CandidatoId = candidatoId,
            VagaId = vagaId
        });

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException exception)
            when (exception.GetBaseException() is SqlException { Number: 2601 or 2627 })
        {
            // The composite unique index makes concurrent duplicate requests idempotent.
        }

        return NoContent();
    }

    [HttpDelete("{vagaId:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Remover(
        int vagaId,
        CancellationToken cancellationToken)
    {
        var candidatoId = CandidatoId;
        var favorito = await db.Favoritos.SingleOrDefaultAsync(
            item => item.CandidatoId == candidatoId && item.VagaId == vagaId,
            cancellationToken);
        if (favorito is null)
        {
            return NoContent();
        }

        db.Favoritos.Remove(favorito);
        await db.SaveChangesAsync(cancellationToken);
        return NoContent();
    }
}
