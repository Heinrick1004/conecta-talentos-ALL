namespace ConectaTalentos.Api.Models;

public sealed class Notificacao
{
    public int Id { get; set; }
    public int CandidatoId { get; set; }
    public int CandidaturaId { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public string Mensagem { get; set; } = string.Empty;
    public bool Lida { get; set; }
    public DateTime CriadoEm { get; set; }

    public Candidato Candidato { get; set; } = null!;
    public Candidatura Candidatura { get; set; } = null!;
}