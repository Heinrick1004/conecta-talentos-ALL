namespace ConectaTalentos.Api.Models;

public sealed class Empresa
{
    public int Id { get; set; }
    public string NomeFantasia { get; set; } = string.Empty;
    public string RazaoSocial { get; set; } = string.Empty;
    public string CNPJ { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string SenhaHash { get; set; } = string.Empty;
    public string? Telefone { get; set; }
    public string? Cidade { get; set; }
    public string? UF { get; set; }
    public DateTime CriadoEm { get; set; }

    public ICollection<Vaga> Vagas { get; set; } = new List<Vaga>();
}