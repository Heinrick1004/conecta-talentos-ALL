using System.ComponentModel.DataAnnotations;

namespace ConectaTalentos.Api.DTOs;

public sealed class LoginRequest
{
    [Required(ErrorMessage = "O e-mail é obrigatório.")]
    [EmailAddress(ErrorMessage = "Informe um e-mail válido.")]
    [StringLength(254, ErrorMessage = "O e-mail deve ter no máximo 254 caracteres.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "A senha é obrigatória.")]
    public string Senha { get; set; } = string.Empty;
}

public sealed class RegistroEmpresaRequest
{
    [Required(ErrorMessage = "O nome fantasia é obrigatório.")]
    [StringLength(150, ErrorMessage = "O nome fantasia deve ter no máximo 150 caracteres.")]
    public string NomeFantasia { get; set; } = string.Empty;

    [Required(ErrorMessage = "A razão social é obrigatória.")]
    [StringLength(200, ErrorMessage = "A razão social deve ter no máximo 200 caracteres.")]
    public string RazaoSocial { get; set; } = string.Empty;

    [Required(ErrorMessage = "O CNPJ é obrigatório.")]
    [RegularExpression("^\\d{14}$", ErrorMessage = "O CNPJ deve conter exatamente 14 dígitos, sem pontuação.")]
    public string Cnpj { get; set; } = string.Empty;

    [Required(ErrorMessage = "O e-mail é obrigatório.")]
    [EmailAddress(ErrorMessage = "Informe um e-mail válido.")]
    [StringLength(254, ErrorMessage = "O e-mail deve ter no máximo 254 caracteres.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "A senha é obrigatória.")]
    [MinLength(8, ErrorMessage = "A senha deve ter pelo menos 8 caracteres.")]
    public string Senha { get; set; } = string.Empty;

    [StringLength(30, ErrorMessage = "O telefone deve ter no máximo 30 caracteres.")]
    public string? Telefone { get; set; }

    [StringLength(100, ErrorMessage = "A cidade deve ter no máximo 100 caracteres.")]
    public string? Cidade { get; set; }

    [RegularExpression("^[A-Za-z]{2}$", ErrorMessage = "Informe uma UF com duas letras.")]
    public string? Uf { get; set; }
}

public sealed record EmpresaResumoDto(int Id, string NomeFantasia);
public sealed record AuthResponse(string Token, EmpresaResumoDto Empresa);