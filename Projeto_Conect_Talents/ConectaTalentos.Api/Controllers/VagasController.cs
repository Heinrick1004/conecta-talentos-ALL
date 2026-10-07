using System.Linq.Expressions;
using ConectaTalentos.Api.Data;
using ConectaTalentos.Api.DTOs;
using ConectaTalentos.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ConectaTalentos.Api.Controllers;

[Authorize(Roles = "Empresa")]
[Route("api/vagas")]
public sealed class VagasController(ConectaTalentosContext db) : TenantControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<VagaResponse>>> Listar(CancellationToken cancellationToken)
    {
        var vagas = await db.Vagas.AsNoTracking()
            .Where(vaga => vaga.EmpresaId == EmpresaId)
            .OrderByDescending(vaga => vaga.CriadoEm)
            .Select(ToResponse())
            .ToListAsync(cancellationToken);

        return Ok(vagas);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<VagaResponse>> ObterPorId(int id, CancellationToken cancellationToken)
    {
        var vaga = await db.Vagas.AsNoTracking()
            .Where(item => item.Id == id && item.EmpresaId == EmpresaId)
            .Select(ToResponse())
            .SingleOrDefaultAsync(cancellationToken);

        return vaga is null ? NotFound(new { erro = "Vaga não encontrada." }) : Ok(vaga);
    }

    [HttpPost]
    public async Task<ActionResult<VagaResponse>> Criar(VagaWriteRequest request, CancellationToken cancellationToken)
    {
        if (!PeriodoValido(request)) return BadRequest(new { erro = "DataFim deve ser posterior a DataInicio." });

        var vaga = new Vaga
        {
            EmpresaId = EmpresaId,
            Titulo = request.Titulo.Trim(),
            Descricao = request.Descricao.Trim(),
            Requisitos = request.Requisitos.Trim(),
            Cidade = request.Cidade.Trim(),
            UF = request.Uf.Trim().ToUpperInvariant(),
            Modalidade = request.Modalidade,
            Status = request.Status,
            DataInicio = request.DataInicio!.Value,
            DataFim = request.DataFim!.Value
        };

        db.Vagas.Add(vaga);
        await db.SaveChangesAsync(cancellationToken);

        var response = await db.Vagas.AsNoTracking().Where(item => item.Id == vaga.Id)
            .Select(ToResponse()).SingleAsync(cancellationToken);
        return CreatedAtAction(nameof(ObterPorId), new { id = vaga.Id }, response);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<VagaResponse>> Atualizar(int id, VagaWriteRequest request, CancellationToken cancellationToken)
    {
        if (!PeriodoValido(request)) return BadRequest(new { erro = "DataFim deve ser posterior a DataInicio." });

        var vaga = await db.Vagas.SingleOrDefaultAsync(
            item => item.Id == id && item.EmpresaId == EmpresaId, cancellationToken);
        if (vaga is null) return NotFound(new { erro = "Vaga não encontrada." });

        vaga.Titulo = request.Titulo.Trim();
        vaga.Descricao = request.Descricao.Trim();
        vaga.Requisitos = request.Requisitos.Trim();
        vaga.Cidade = request.Cidade.Trim();
        vaga.UF = request.Uf.Trim().ToUpperInvariant();
        vaga.Modalidade = request.Modalidade;
        vaga.Status = request.Status;
        vaga.DataInicio = request.DataInicio!.Value;
        vaga.DataFim = request.DataFim!.Value;
        await db.SaveChangesAsync(cancellationToken);

        var response = await db.Vagas.AsNoTracking().Where(item => item.Id == id)
            .Select(ToResponse()).SingleAsync(cancellationToken);
        return Ok(response);
    }

    [HttpPatch("{id:int}/encerrar")]
    public async Task<ActionResult<VagaResponse>> Encerrar(int id, CancellationToken cancellationToken)
    {
        var vaga = await db.Vagas.SingleOrDefaultAsync(
            item => item.Id == id && item.EmpresaId == EmpresaId, cancellationToken);
        if (vaga is null) return NotFound(new { erro = "Vaga não encontrada." });

        vaga.Status = "Encerrada";
        await db.SaveChangesAsync(cancellationToken);

        var response = await db.Vagas.AsNoTracking().Where(item => item.Id == id)
            .Select(ToResponse()).SingleAsync(cancellationToken);
        return Ok(response);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Excluir(int id, CancellationToken cancellationToken)
    {
        var vaga = await db.Vagas.SingleOrDefaultAsync(
            item => item.Id == id && item.EmpresaId == EmpresaId, cancellationToken);
        if (vaga is null) return NotFound(new { erro = "Vaga não encontrada." });
        if (vaga.Status != "Encerrada") return BadRequest(new { erro = "Somente vagas encerradas podem ser excluídas." });

        db.Vagas.Remove(vaga);
        await db.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private static bool PeriodoValido(VagaWriteRequest request)
    {
        return request.DataInicio.HasValue && request.DataFim.HasValue && request.DataFim.Value > request.DataInicio.Value;
    }

    private static Expression<Func<Vaga, VagaResponse>> ToResponse()
    {
        return vaga => new VagaResponse(
            vaga.Id,
            vaga.Empresa.NomeFantasia,
            vaga.Titulo,
            vaga.Descricao,
            vaga.Requisitos,
            vaga.Cidade,
            vaga.UF,
            vaga.Modalidade,
            vaga.Status,
            vaga.DataInicio,
            vaga.DataFim,
            vaga.CriadoEm,
            vaga.AtualizadoEm,
            vaga.Candidaturas.Count);
    }
}