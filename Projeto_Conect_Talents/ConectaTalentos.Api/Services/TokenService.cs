using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using ConectaTalentos.Api.DTOs;
using ConectaTalentos.Api.Models;
using Microsoft.IdentityModel.Tokens;

namespace ConectaTalentos.Api.Services;

public sealed class TokenService(IConfiguration configuration)
{
    public AuthResponse CreateToken(Empresa empresa)
    {
        var secret = configuration["Jwt:Secret"];
        if (string.IsNullOrWhiteSpace(secret) || Encoding.UTF8.GetByteCount(secret) < 32)
        {
            throw new InvalidOperationException("A chave Jwt:Secret deve ter pelo menos 32 bytes.");
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expiresAt = DateTime.UtcNow.AddHours(configuration.GetValue<int?>("Jwt:ExpiryHours") ?? 8);
        var claims = new[]
        {
            new Claim("tipo", "Empresa"),
            new Claim("empresaId", empresa.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, empresa.Email),
            new Claim(JwtRegisteredClaimNames.Sub, empresa.Id.ToString())
        };

        var token = new JwtSecurityToken(
            issuer: configuration["Jwt:Issuer"],
            audience: configuration["Jwt:Audience"],
            claims: claims,
            expires: expiresAt,
            signingCredentials: credentials);

        return new AuthResponse(new JwtSecurityTokenHandler().WriteToken(token), new EmpresaResumoDto(empresa.Id, empresa.NomeFantasia));
    }

    public CandidatoLoginResponse CreateToken(Candidato candidato)
    {
        var secret = configuration["Jwt:Secret"];
        if (string.IsNullOrWhiteSpace(secret) || Encoding.UTF8.GetByteCount(secret) < 32)
        {
            throw new InvalidOperationException("A chave Jwt:Secret deve ter pelo menos 32 bytes.");
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expiresAt = DateTime.UtcNow.AddHours(configuration.GetValue<int?>("Jwt:ExpiryHours") ?? 8);
        var claims = new[]
        {
            new Claim("tipo", "Candidato"),
            new Claim("candidatoId", candidato.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, candidato.Email),
            new Claim(JwtRegisteredClaimNames.Sub, candidato.Id.ToString())
        };

        var token = new JwtSecurityToken(
            issuer: configuration["Jwt:Issuer"],
            audience: configuration["Jwt:Audience"],
            claims: claims,
            expires: expiresAt,
            signingCredentials: credentials);

        return new CandidatoLoginResponse(
            new JwtSecurityTokenHandler().WriteToken(token),
            new CandidatoAuthDto(candidato.Id, candidato.NomeCompleto, candidato.Email));
    }
}