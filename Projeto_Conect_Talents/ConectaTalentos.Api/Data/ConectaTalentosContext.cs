using ConectaTalentos.Api.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;

namespace ConectaTalentos.Api.Data;

public sealed class ConectaTalentosContext(DbContextOptions<ConectaTalentosContext> options) : DbContext(options)
{
    public DbSet<Empresa> Empresas => Set<Empresa>();
    public DbSet<Candidato> Candidatos => Set<Candidato>();
    public DbSet<Vaga> Vagas => Set<Vaga>();
    public DbSet<Candidatura> Candidaturas => Set<Candidatura>();
    public DbSet<Notificacao> Notificacoes => Set<Notificacao>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Empresa>(entity =>
        {
            entity.ToTable("Empresa");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("Id").UseIdentityColumn();
            entity.Property(e => e.NomeFantasia).HasColumnName("NomeFantasia").HasMaxLength(150).IsRequired();
            entity.Property(e => e.RazaoSocial).HasColumnName("RazaoSocial").HasMaxLength(200).IsRequired();
            entity.Property(e => e.CNPJ).HasColumnName("CNPJ").HasColumnType("char(14)").IsUnicode(false).HasMaxLength(14).IsRequired();
            entity.Property(e => e.Email).HasColumnName("Email").HasColumnType("varchar(254)").IsUnicode(false).HasMaxLength(254).IsRequired();
            entity.Property(e => e.SenhaHash).HasColumnName("SenhaHash").HasColumnType("varchar(255)").IsUnicode(false).HasMaxLength(255).IsRequired();
            entity.Property(e => e.Telefone).HasColumnName("Telefone").HasColumnType("varchar(30)").IsUnicode(false).HasMaxLength(30);
            entity.Property(e => e.Cidade).HasColumnName("Cidade").HasMaxLength(100);
            entity.Property(e => e.UF).HasColumnName("UF").HasColumnType("char(2)").IsUnicode(false).HasMaxLength(2);
            entity.Property(e => e.CriadoEm).HasColumnName("CriadoEm").HasColumnType("datetime").HasDefaultValueSql("(getdate())");
            entity.HasIndex(e => e.CNPJ).IsUnique();
            entity.HasIndex(e => e.Email).IsUnique();
        });

        modelBuilder.Entity<Candidato>(entity =>
        {
            entity.ToTable("Candidato");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("Id").UseIdentityColumn();
            entity.Property(e => e.NomeCompleto).HasColumnName("NomeCompleto").HasMaxLength(150).IsRequired();
            entity.Property(e => e.Email).HasColumnName("Email").HasColumnType("varchar(254)").IsUnicode(false).HasMaxLength(254).IsRequired();
            entity.Property(e => e.SenhaHash).HasColumnName("SenhaHash").HasColumnType("varchar(255)").IsUnicode(false).HasMaxLength(255).IsRequired();
            entity.Property(e => e.Telefone).HasColumnName("Telefone").HasColumnType("varchar(30)").IsUnicode(false).HasMaxLength(30);
            entity.Property(e => e.Cidade).HasColumnName("Cidade").HasMaxLength(100);
            entity.Property(e => e.UF).HasColumnName("UF").HasColumnType("char(2)").IsUnicode(false).HasMaxLength(2);
            entity.Property(e => e.Habilidades).HasColumnName("Habilidades").HasColumnType("nvarchar(max)");
            entity.Property(e => e.CriadoEm).HasColumnName("CriadoEm").HasColumnType("datetime").HasDefaultValueSql("(getdate())");
            entity.HasIndex(e => e.Email).IsUnique();
        });

        modelBuilder.Entity<Vaga>(entity =>
        {
            entity.ToTable("Vaga", table => table.HasTrigger("TR_Vaga_AtualizarEm"));
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("Id").UseIdentityColumn();
            entity.Property(e => e.EmpresaId).HasColumnName("EmpresaId").IsRequired();
            entity.Property(e => e.Titulo).HasColumnName("Titulo").HasMaxLength(150).IsRequired();
            entity.Property(e => e.Descricao).HasColumnName("Descricao").HasColumnType("nvarchar(max)").IsRequired();
            entity.Property(e => e.Requisitos).HasColumnName("Requisitos").HasColumnType("nvarchar(max)").IsRequired();
            entity.Property(e => e.Cidade).HasColumnName("Cidade").HasMaxLength(100).IsRequired();
            entity.Property(e => e.UF).HasColumnName("UF").HasColumnType("char(2)").IsUnicode(false).HasMaxLength(2).IsRequired();
            entity.Property(e => e.Modalidade).HasColumnName("Modalidade").HasColumnType("varchar(20)").IsUnicode(false).HasMaxLength(20).IsRequired();
            entity.Property(e => e.Status).HasColumnName("Status").HasColumnType("varchar(20)").IsUnicode(false).HasMaxLength(20).HasDefaultValue("Aberta").IsRequired();
            entity.Property(e => e.DataInicio).HasColumnName("DataInicio").HasColumnType("date").IsRequired();
            entity.Property(e => e.DataFim).HasColumnName("DataFim").HasColumnType("date").IsRequired();
            entity.Property(e => e.CriadoEm).HasColumnName("CriadoEm").HasColumnType("datetime").HasDefaultValueSql("(getdate())");
            var atualizadoEm = entity.Property(e => e.AtualizadoEm).HasColumnName("AtualizadoEm").HasColumnType("datetime").HasDefaultValueSql("(getdate())").ValueGeneratedOnAddOrUpdate();
            atualizadoEm.Metadata.SetBeforeSaveBehavior(PropertySaveBehavior.Ignore);
            atualizadoEm.Metadata.SetAfterSaveBehavior(PropertySaveBehavior.Ignore);
            entity.HasIndex(e => e.EmpresaId);
            entity.HasOne(e => e.Empresa).WithMany(e => e.Vagas).HasForeignKey(e => e.EmpresaId).OnDelete(DeleteBehavior.NoAction);
        });

        modelBuilder.Entity<Candidatura>(entity =>
        {
            entity.ToTable("Candidatura", table => table.HasTrigger("TR_Candidatura_AtualizarENotificar"));
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("Id").UseIdentityColumn();
            entity.Property(e => e.VagaId).HasColumnName("VagaId").IsRequired();
            entity.Property(e => e.CandidatoId).HasColumnName("CandidatoId").IsRequired();
            entity.Property(e => e.Status).HasColumnName("Status").HasColumnType("varchar(20)").IsUnicode(false).HasMaxLength(20).HasDefaultValue("Pendente").IsRequired();
            entity.Property(e => e.DataCandidatura).HasColumnName("DataCandidatura").HasColumnType("datetime").HasDefaultValueSql("(getdate())");
            var atualizadoEm = entity.Property(e => e.AtualizadoEm).HasColumnName("AtualizadoEm").HasColumnType("datetime").HasDefaultValueSql("(getdate())").ValueGeneratedOnAddOrUpdate();
            atualizadoEm.Metadata.SetBeforeSaveBehavior(PropertySaveBehavior.Ignore);
            atualizadoEm.Metadata.SetAfterSaveBehavior(PropertySaveBehavior.Ignore);
            entity.HasIndex(e => new { e.VagaId, e.CandidatoId }).IsUnique();
            entity.HasAlternateKey(e => new { e.Id, e.CandidatoId });
            entity.HasOne(e => e.Vaga).WithMany(e => e.Candidaturas).HasForeignKey(e => e.VagaId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.Candidato).WithMany(e => e.Candidaturas).HasForeignKey(e => e.CandidatoId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Notificacao>(entity =>
        {
            entity.ToTable("Notificacao");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("Id").UseIdentityColumn();
            entity.Property(e => e.CandidatoId).HasColumnName("CandidatoId").IsRequired();
            entity.Property(e => e.CandidaturaId).HasColumnName("CandidaturaId").IsRequired();
            entity.Property(e => e.Titulo).HasColumnName("Titulo").HasMaxLength(100).IsRequired();
            entity.Property(e => e.Mensagem).HasColumnName("Mensagem").HasMaxLength(300).IsRequired();
            entity.Property(e => e.Lida).HasColumnName("Lida").HasDefaultValue(false).IsRequired();
            entity.Property(e => e.CriadoEm).HasColumnName("CriadoEm").HasColumnType("datetime").HasDefaultValueSql("(getdate())");
            entity.HasIndex(e => e.CandidatoId);
            entity.HasOne(e => e.Candidato).WithMany(e => e.Notificacoes).HasForeignKey(e => e.CandidatoId).OnDelete(DeleteBehavior.NoAction);
            entity.HasOne(e => e.Candidatura).WithMany(e => e.Notificacoes).HasForeignKey(e => new { e.CandidaturaId, e.CandidatoId }).HasPrincipalKey(e => new { e.Id, e.CandidatoId }).OnDelete(DeleteBehavior.Cascade);
        });
    }
}