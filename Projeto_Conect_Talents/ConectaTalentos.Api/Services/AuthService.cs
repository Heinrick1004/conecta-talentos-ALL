using ConectaTalentos.Api.Data;
using ConectaTalentos.Api.DTOs;
using ConectaTalentos.Api.Models;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace ConectaTalentos.Api.Services;

public sealed class AuthService(ConectaTalentosContext db, TokenService tokenService)
{
    public async Task<AuthResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim();
        var empresa = await db.Empresas.AsNoTracking()
            .SingleOrDefaultAsync(item => item.Email == email, cancellationToken);

        if (empresa is null || !SenhaValida(request.Senha, empresa.SenhaHash))
        {
            return null;
        }

        return tokenService.CreateToken(empresa);
    }

    public async Task<CandidatoLoginResponse?> LoginCandidatoAsync(
        CandidatoLoginRequest request,
        CancellationToken cancellationToken)
    {
        var email = request.Email.Trim();
        var candidato = await db.Candidatos.AsNoTracking()
            .SingleOrDefaultAsync(item => item.Email == email, cancellationToken);

        if (candidato is null || !SenhaValida(request.Senha, candidato.SenhaHash))
        {
            return null;
        }

        return tokenService.CreateToken(candidato);
    }

    public async Task<(CandidatoLoginResponse? Response, string? Error)> RegistrarCandidatoAsync(
        CandidatoRegistroRequest request,
        CancellationToken cancellationToken)
    {
        var email = request.Email.Trim();
        if (await db.Candidatos.AnyAsync(item => item.Email == email, cancellationToken))
        {
            return (null, "Este e-mail já está cadastrado.");
        }

        var candidato = new Candidato
        {
            NomeCompleto = request.NomeCompleto.Trim(),
            Email = email,
            SenhaHash = BCrypt.Net.BCrypt.HashPassword(request.Senha),
            Telefone = EmptyToNull(request.Telefone),
            Cidade = EmptyToNull(request.Cidade),
            UF = EmptyToNull(request.Uf)?.ToUpperInvariant(),
            Habilidades = EmptyToNull(request.Habilidades)
        };

        db.Candidatos.Add(candidato);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException exception) when (IsUniqueConstraintViolation(exception))
        {
            return (null, "Este e-mail já está cadastrado.");
        }

        return (tokenService.CreateToken(candidato), null);
    }

    public async Task<(AuthResponse? Response, string? Error)> RegistrarAsync(
        RegistroEmpresaRequest request,
        CancellationToken cancellationToken)
    {
        var email = request.Email.Trim();
        var cnpj = request.Cnpj.Trim();

        if (await db.Empresas.AnyAsync(item => item.Email == email, cancellationToken))
        {
            return (null, "Este e-mail já está cadastrado.");
        }

        if (await db.Empresas.AnyAsync(item => item.CNPJ == cnpj, cancellationToken))
        {
            return (null, "Este CNPJ já está cadastrado.");
        }

        var empresa = new Empresa
        {
            NomeFantasia = request.NomeFantasia.Trim(),
            RazaoSocial = request.RazaoSocial.Trim(),
            CNPJ = cnpj,
            Email = email,
            SenhaHash = BCrypt.Net.BCrypt.HashPassword(request.Senha),
            Telefone = EmptyToNull(request.Telefone),
            Cidade = EmptyToNull(request.Cidade),
            UF = EmptyToNull(request.Uf)?.ToUpperInvariant()
        };

        db.Empresas.Add(empresa);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException exception) when (IsUniqueConstraintViolation(exception))
        {
            return (null, "Este CNPJ ou e-mail já está cadastrado.");
        }

        return (tokenService.CreateToken(empresa), null);
    }

    private static bool SenhaValida(string senha, string senhaHash)
    {
        try
        {
            return BCrypt.Net.BCrypt.Verify(senha, senhaHash);
        }
        catch (Exception exception) when (exception is BCrypt.Net.SaltParseException or ArgumentException)
        {
            // Os marcadores dos dados de exemplo não são hashes de autenticação.
            return false;
        }
    }

    private static string? EmptyToNull(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private static bool IsUniqueConstraintViolation(Exception exception)
    {
        return exception.GetBaseException() is SqlException { Number: 2601 or 2627 };
    }
}
