namespace ConectaTalentos.Api.Models;

public sealed class Candidato
{
    public int Id { get; set; }
    public string NomeCompleto { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string SenhaHash { get; set; } = string.Empty;
    public string? Telefone { get; set; }
    public string? Cidade { get; set; }
    public string? UF { get; set; }
    public string? Habilidades { get; set; }
    public DateTime CriadoEm { get; set; }

    public ICollection<Candidatura> Candidaturas { get; set; } = new List<Candidatura>();
    public ICollection<Notificacao> Notificacoes { get; set; } = new List<Notificacao>();
    public ICollection<Favorito> Favoritos { get; set; } = new List<Favorito>();
}