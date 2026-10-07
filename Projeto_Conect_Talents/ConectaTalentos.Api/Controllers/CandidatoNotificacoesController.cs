using ConectaTalentos.Api.Data;
using ConectaTalentos.Api.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ConectaTalentos.Api.Controllers;

[Authorize(Roles = "Candidato")]
[Route("api/candidato/notificacoes")]
public sealed class CandidatoNotificacoesController(ConectaTalentosContext db) : TenantControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<NotificacaoDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<NotificacaoDto>>> Listar(CancellationToken cancellationToken)
    {
        var candidatoId = CandidatoId;
        var notificacoes = await db.Notificacoes.AsNoTracking()
            .Where(item => item.CandidatoId == candidatoId)
            .OrderByDescending(item => item.CriadoEm)
            .Select(item => new NotificacaoDto(
                item.Id,
                item.Titulo,
                item.Mensagem,
                item.Lida,
                item.CriadoEm,
                item.CandidaturaId))
            .ToListAsync(cancellationToken);

        return Ok(notificacoes);
    }

    [HttpPatch("{id:int}/marcar-lida")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MarcarLida(int id, CancellationToken cancellationToken)
    {
        var candidatoId = CandidatoId;
        var notificacao = await db.Notificacoes.SingleOrDefaultAsync(
            item => item.Id == id && item.CandidatoId == candidatoId,
            cancellationToken);
        if (notificacao is null)
        {
            return NotFound(new { erro = "Notificação não encontrada." });
        }

        notificacao.Lida = true;
        await db.SaveChangesAsync(cancellationToken);
        return NoContent();
    }
}