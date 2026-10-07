namespace ConectaTalentos.Api.Models;

public sealed class Candidatura
{
    public int Id { get; set; }
    public int VagaId { get; set; }
    public int CandidatoId { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime DataCandidatura { get; set; }
    public DateTime AtualizadoEm { get; set; }

    public Vaga Vaga { get; set; } = null!;
    public Candidato Candidato { get; set; } = null!;
    public ICollection<Notificacao> Notificacoes { get; set; } = new List<Notificacao>();
}