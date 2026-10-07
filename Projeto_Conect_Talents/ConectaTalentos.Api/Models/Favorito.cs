namespace ConectaTalentos.Api.Models;

public sealed class Favorito
{
    public int Id { get; set; }
    public int CandidatoId { get; set; }
    public int VagaId { get; set; }
    public DateTime CriadoEm { get; set; }

    public Candidato Candidato { get; set; } = null!;
    public Vaga Vaga { get; set; } = null!;
}
