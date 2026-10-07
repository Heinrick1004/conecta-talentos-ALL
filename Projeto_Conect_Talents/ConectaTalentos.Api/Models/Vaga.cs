namespace ConectaTalentos.Api.Models;

public sealed class Vaga
{
    public int Id { get; set; }
    public int EmpresaId { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public string Descricao { get; set; } = string.Empty;
    public string Requisitos { get; set; } = string.Empty;
    public string Cidade { get; set; } = string.Empty;
    public string UF { get; set; } = string.Empty;
    public string Modalidade { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateOnly DataInicio { get; set; }
    public DateOnly DataFim { get; set; }
    public DateTime CriadoEm { get; set; }
    public DateTime AtualizadoEm { get; set; }

    public Empresa Empresa { get; set; } = null!;
    public ICollection<Candidatura> Candidaturas { get; set; } = new List<Candidatura>();
    public ICollection<Favorito> Favoritos { get; set; } = new List<Favorito>();
}