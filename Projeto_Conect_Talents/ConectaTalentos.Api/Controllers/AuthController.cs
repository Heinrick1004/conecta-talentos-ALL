using ConectaTalentos.Api.DTOs;
using ConectaTalentos.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ConectaTalentos.Api.Controllers;

[AllowAnonymous]
[Route("api/auth/empresa")]
public sealed class AuthController(AuthService authService) : TenantControllerBase
{
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request, CancellationToken cancellationToken)
    {
        var response = await authService.LoginAsync(request, cancellationToken);
        return response is null
            ? Unauthorized(new { erro = "E-mail ou senha inválidos." })
            : Ok(response);
    }

    [HttpPost("registrar")]
    public async Task<ActionResult<AuthResponse>> Registrar(RegistroEmpresaRequest request, CancellationToken cancellationToken)
    {
        var result = await authService.RegistrarAsync(request, cancellationToken);
        if (result.Error is not null)
        {
            return Conflict(new { erro = result.Error });
        }

        return Ok(result.Response);
    }

    [HttpPost("~/api/auth/candidato/registrar")]
    [ProducesResponseType(typeof(CandidatoLoginResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CandidatoLoginResponse>> RegistrarCandidato(
        CandidatoRegistroRequest request,
        CancellationToken cancellationToken)
    {
        var result = await authService.RegistrarCandidatoAsync(request, cancellationToken);
        if (result.Error is not null)
        {
            return Conflict(new { erro = result.Error });
        }

        return Created("/api/candidato/perfil", result.Response!);
    }

    [HttpPost("~/api/auth/candidato/login")]
    [ProducesResponseType(typeof(CandidatoLoginResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<CandidatoLoginResponse>> LoginCandidato(
        CandidatoLoginRequest request,
        CancellationToken cancellationToken)
    {
        var response = await authService.LoginCandidatoAsync(request, cancellationToken);
        return response is null
            ? Unauthorized(new { erro = "E-mail ou senha inválidos." })
            : Ok(response);
    }
}