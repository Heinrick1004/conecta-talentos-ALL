using ConectaTalentos.Api.Data;
using ConectaTalentos.Api.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ConectaTalentos.Api.Controllers;

[Authorize(Roles = "Candidato")]
[Route("api/candidato/vagas")]
public sealed class CandidatoVagasController(ConectaTalentosContext db) : TenantControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<VagaPublicaDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<VagaPublicaDto>>> Listar(
        [FromQuery] string? cidade,
        [FromQuery] string? modalidade,
        [FromQuery] DateTime? desde,
        CancellationToken cancellationToken)
    {
        var candidatoId = CandidatoId;
        var query = db.Vagas.AsNoTracking().Where(vaga => vaga.Status == "Aberta");

        if (!string.IsNullOrWhiteSpace(cidade))
        {
            var cidadePattern = $"%{cidade.Trim()}%";
            query = query.Where(vaga => EF.Functions.Like(vaga.Cidade, cidadePattern));
        }

        if (!string.IsNullOrWhiteSpace(modalidade))
        {
            query = query.Where(vaga => vaga.Modalidade == modalidade);
        }

        if (desde.HasValue)
        {
            query = query.Where(vaga => vaga.AtualizadoEm > desde.Value);
        }

        var vagas = await query
            .OrderByDescending(vaga => vaga.CriadoEm)
            .Select(vaga => new VagaPublicaDto(
                vaga.Id,
                vaga.Titulo,
                vaga.Descricao,
                vaga.Requisitos,
                vaga.Cidade,
                vaga.UF,
                vaga.Modalidade,
                vaga.DataInicio,
                vaga.DataFim,
                vaga.Empresa.NomeFantasia,
                vaga.Candidaturas.Any(item => item.CandidatoId == candidatoId),
                vaga.Favoritos.Any(item => item.CandidatoId == candidatoId)))
            .ToListAsync(cancellationToken);

        return Ok(vagas);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(VagaPublicaDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<VagaPublicaDto>> ObterPorId(int id, CancellationToken cancellationToken)
    {
        var candidatoId = CandidatoId;
        var vaga = await db.Vagas.AsNoTracking()
            .Where(item => item.Id == id)
            .Select(item => new VagaPublicaDto(
                item.Id,
                item.Titulo,
                item.Descricao,
                item.Requisitos,
                item.Cidade,
                item.UF,
                item.Modalidade,
                item.DataInicio,
                item.DataFim,
                item.Empresa.NomeFantasia,
                item.Candidaturas.Any(application => application.CandidatoId == candidatoId),
                item.Favoritos.Any(favorite => favorite.CandidatoId == candidatoId)))
            .SingleOrDefaultAsync(cancellationToken);

        return vaga is null ? NotFound(new { erro = "Vaga não encontrada." }) : Ok(vaga);
    }
}