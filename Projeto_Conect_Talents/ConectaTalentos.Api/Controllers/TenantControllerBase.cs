using Microsoft.AspNetCore.Mvc;

namespace ConectaTalentos.Api.Controllers;

[ApiController]
public abstract class TenantControllerBase : ControllerBase
{
    protected int EmpresaId => int.Parse(User.FindFirst("empresaId")!.Value);
    protected int CandidatoId => int.Parse(User.FindFirst("candidatoId")!.Value);
}