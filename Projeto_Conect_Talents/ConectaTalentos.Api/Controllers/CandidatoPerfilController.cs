using ConectaTalentos.Api.Data;
using ConectaTalentos.Api.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ConectaTalentos.Api.Controllers;

[Authorize(Roles = "Candidato")]
[Route("api/candidato/perfil")]
public sealed class CandidatoPerfilController(ConectaTalentosContext db) : TenantControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(PerfilCandidatoDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PerfilCandidatoDto>> Obter(CancellationToken cancellationToken)
    {
        var candidato = await db.Candidatos.AsNoTracking()
            .Where(item => item.Id == CandidatoId)
            .Select(ToPerfil())
            .SingleOrDefaultAsync(cancellationToken);

        return candidato is null
            ? NotFound(new { erro = "Candidato não encontrado." })
            : Ok(candidato);
    }

    [HttpPut]
    [ProducesResponseType(typeof(PerfilCandidatoDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PerfilCandidatoDto>> Atualizar(
        AtualizarPerfilCandidatoRequest request,
        CancellationToken cancellationToken)
    {
        var candidato = await db.Candidatos.SingleOrDefaultAsync(
            item => item.Id == CandidatoId,
            cancellationToken);
        if (candidato is null)
        {
            return NotFound(new { erro = "Candidato não encontrado." });
        }

        candidato.NomeCompleto = request.NomeCompleto.Trim();
        candidato.Telefone = EmptyToNull(request.Telefone);
        candidato.Cidade = EmptyToNull(request.Cidade);
        candidato.UF = EmptyToNull(request.Uf)?.ToUpperInvariant();
        candidato.Habilidades = EmptyToNull(request.Habilidades);
        await db.SaveChangesAsync(cancellationToken);

        var response = await db.Candidatos.AsNoTracking()
            .Where(item => item.Id == candidato.Id)
            .Select(ToPerfil())
            .SingleAsync(cancellationToken);
        return Ok(response);
    }

    private static System.Linq.Expressions.Expression<Func<Models.Candidato, PerfilCandidatoDto>> ToPerfil()
    {
        return candidato => new PerfilCandidatoDto(
            candidato.Id,
            candidato.NomeCompleto,
            candidato.Email,
            candidato.Telefone,
            candidato.Cidade,
            candidato.UF,
            candidato.Habilidades,
            candidato.CriadoEm);
    }

    private static string? EmptyToNull(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}