(function () {
  const applicationProfiles = new Map();

  function apiUrl(path) {
    return `${window.API_BASE_URL.replace(/\/+$/, '')}${path}`;
  }

  function authHeaders() {
    return {
      Authorization: `Bearer ${AuthData.getToken()}`,
      'Content-Type': 'application/json'
    };
  }

  async function request(path, options = {}) {
    let response;
    try {
      response = await fetch(apiUrl(path), {
        ...options,
        headers: { ...authHeaders(), ...(options.headers || {}) }
      });
    } catch {
      throw new Error('Não foi possível conectar à API. Tente novamente.');
    }

    if (response.status === 401) {
      localStorage.removeItem('conectatalentos_token');
      localStorage.removeItem('conectatalentos_empresa');
      window.location.replace('login.html');
      throw new Error('Sua sessão expirou. Entre novamente.');
    }

    const body = await response.json().catch(() => null);
    if (!response.ok) {
      throw new Error(body?.message || body?.title || body?.erro || 'Não foi possível concluir a solicitação.');
    }
    return body;
  }

  function value(source, ...keys) {
    if (!source) return undefined;
    for (const key of keys) {
      if (source[key] !== undefined && source[key] !== null) return source[key];
      const pascalKey = key.charAt(0).toUpperCase() + key.slice(1);
      if (source[pascalKey] !== undefined && source[pascalKey] !== null) return source[pascalKey];
    }
    return undefined;
  }

  function unwrap(payload) {
    return payload?.data ?? payload?.items ?? payload?.result ?? payload;
  }

  function collection(payload) {
    const result = unwrap(payload);
    if (Array.isArray(result)) return result;
    return result ? [result] : [];
  }

  function location(city, uf) {
    return [city, uf].filter(Boolean).join(' - ');
  }

  function initials(name) {
    return String(name || '')
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map(part => part.charAt(0).toUpperCase())
      .join('');
  }

  function fallbackAvatar(name, id) {
    const colors = ['#B83D13', '#276749', '#245A81', '#7A4B2A', '#5D536B'];
    const label = initials(name).replace(/[&<>"']/g, '');
    const color = colors[Math.abs(Number(id) || 0) % colors.length];
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" fill="${color}"/><text x="50" y="55" text-anchor="middle" dominant-baseline="middle" fill="white" font-family="Arial,sans-serif" font-size="36">${label}</text></svg>`;
    return `data:image/svg+xml,${encodeURIComponent(svg)}`;
  }

  function normalizeVacancy(source) {
    const city = value(source, 'cidade', 'city') || '';
    const uf = value(source, 'uf', 'estado', 'state') || '';
    const modality = value(source, 'modalidade', 'tipo', 'type') || '';
    const company = value(source, 'empresa', 'company');
    const id = value(source, 'id');
    const colors = ['blue', 'purple', 'teal', 'orange', 'pink'];
    const icons = ['code', 'chart', 'users', 'megaphone', 'headset'];
    return {
      ...source,
      id,
      titulo: value(source, 'titulo', 'title') || '',
      empresa: typeof company === 'string' ? company : value(company, 'nomeFantasia', 'name') || AuthData.getEmpresaLogada()?.nomeFantasia || '',
      descricao: value(source, 'descricao', 'description') || '',
      requisitos: value(source, 'requisitos', 'requirements') || '',
      cidade: city,
      estado: uf,
      localizacao: value(source, 'localizacao', 'location') || location(city, uf),
      tipo: modality === 'Hibrido' ? 'Híbrido' : modality,
      status: value(source, 'status') || 'Aberta',
      dataInicio: String(value(source, 'dataInicio', 'startDate') || '').slice(0, 10),
      dataFim: String(value(source, 'dataFim', 'endDate') || '').slice(0, 10),
      candidaturas: Number(value(source, 'candidaturas', 'totalCandidaturas', 'quantidadeCandidaturas') || 0),
      cor: colors.includes(value(source, 'cor')) ? value(source, 'cor') : colors[Math.abs(Number(id) || 0) % colors.length],
      icone: icons.includes(value(source, 'icone')) ? value(source, 'icone') : icons[Math.abs(Number(id) || 0) % icons.length]
    };
  }

  function normalizeApplication(source) {
    const candidate = value(source, 'candidato', 'candidate');
    const vacancy = value(source, 'vaga', 'vacancy');
    return {
      ...source,
      id: value(source, 'id'),
      candidatoId: value(source, 'candidatoId', 'candidateId') ?? value(candidate, 'id'),
      vagaId: value(source, 'vagaId', 'vacancyId') ?? value(vacancy, 'id'),
      status: value(source, 'status') || 'Pendente',
      candidato: candidate ? normalizeCandidate(candidate) : undefined,
      vaga: vacancy ? normalizeVacancy(vacancy) : undefined
    };
  }

  function normalizeCandidate(source) {
    const rawSkills = value(source, 'habilidades', 'skills');
    const skills = Array.isArray(rawSkills)
      ? rawSkills
      : String(rawSkills || '').split(/[;,|]/).map(skill => skill.trim()).filter(Boolean);
    const name = value(source, 'nomeCompleto', 'nome', 'name') || '';
    const city = value(source, 'cidade', 'city') || '';
    const uf = value(source, 'uf', 'estado', 'state') || '';
    const applications = collection(value(source, 'candidaturas', 'applications'));
    const jobTitle = value(source, 'cargo', 'role') || value(value(applications[0], 'vaga', 'vacancy'), 'titulo', 'title') || 'Candidato';
    const providedStatus = value(source, 'status');
    const derivedStatus = applications.some(item => value(item, 'status') === 'Pendente') ? 'avaliacao' : 'sem_info';
    const allowedStatuses = ['disponivel', 'avaliacao', 'indisponivel', 'sem_info'];
    const status = allowedStatuses.includes(providedStatus) ? providedStatus : derivedStatus;
    const statusLabels = { disponivel: 'Disponível', avaliacao: 'Em avaliação', indisponivel: 'Indisponível', sem_info: 'Sem informação' };
    const id = value(source, 'id');
    return {
      ...source,
      id,
      nome: name,
      cargo: jobTitle,
      localizacao: value(source, 'localizacao', 'location') || location(city, uf),
      email: value(source, 'email') || '',
      telefone: value(source, 'telefone', 'phone') || '',
      habilidades: skills,
      status,
      statusLabel: value(source, 'statusLabel') || statusLabels[status] || 'Sem informação',
      avatar: value(source, 'avatar', 'foto') || fallbackAvatar(name, id)
    };
  }

  function formatDate(isoString) {
    const match = String(isoString || '').slice(0, 10).match(/^(\d{4})-(\d{2})-(\d{2})$/);
    return match ? `${match[3]}/${match[2]}/${match[1]}` : '';
  }

  function escapeHtml(input) {
    return String(input ?? '').replace(/[&<>"']/g, character => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    })[character]);
  }

  async function getCandidate(id) {
    const payload = unwrap(await request(`/candidatos/${encodeURIComponent(id)}`));
    const candidateSource = value(payload, 'candidato') || payload;
    const rawApplications = collection(value(payload, 'candidaturas', 'applications') || value(candidateSource, 'candidaturas', 'applications'));
    const candidate = normalizeCandidate({ ...candidateSource, candidaturas: rawApplications });
    applicationProfiles.set(String(candidate.id), rawApplications.map(normalizeApplication));
    return candidate;
  }

  window.HiringData = {
    async getVacancies() {
      return collection(await request('/vagas')).map(normalizeVacancy);
    },
    async getCandidates() {
      return collection(await request('/candidatos')).map(normalizeCandidate);
    },
    async getVacancy(id) {
      const payload = unwrap(await request(`/vagas/${encodeURIComponent(id)}`));
      return payload ? normalizeVacancy(payload) : null;
    },
    getCandidate,
    async getApplicationsForVacancy(vagaId) {
      return collection(await request(`/vagas/${encodeURIComponent(vagaId)}/candidaturas`)).map(normalizeApplication);
    },
    async getApplicationsForCandidate(candidateId) {
      const key = String(candidateId);
      if (!applicationProfiles.has(key)) await getCandidate(candidateId);
      return applicationProfiles.get(key) || [];
    },
    async saveVacancy(formData) {
      const id = formData.id;
      const editing = id !== undefined && id !== null && id !== '';
      const payload = {
        titulo: formData.titulo,
        descricao: formData.descricao,
        requisitos: formData.requisitos,
        cidade: formData.cidade,
        uf: formData.estado || formData.uf,
        modalidade: formData.tipo === 'Híbrido' ? 'Hibrido' : formData.tipo,
        status: formData.status,
        dataInicio: formData.dataInicio,
        dataFim: formData.dataFim
      };
      const result = unwrap(await request(editing ? `/vagas/${encodeURIComponent(id)}` : '/vagas', {
        method: editing ? 'PUT' : 'POST',
        body: JSON.stringify(payload)
      }));
      return normalizeVacancy(result);
    },
    async closeVacancy(id) {
      const result = await request(`/vagas/${encodeURIComponent(id)}/encerrar`, { method: 'PATCH' });
      return result ? normalizeVacancy(unwrap(result)) : null;
    },
    async deleteVacancy(id) {
      await request(`/vagas/${encodeURIComponent(id)}`, { method: 'DELETE' });
      return true;
    },
    async decideApplication(applicationId, decision) {
      const result = await request(`/candidaturas/${encodeURIComponent(applicationId)}/decidir`, {
        method: 'PATCH',
        body: JSON.stringify({ decisao: decision })
      });
      return result ? normalizeApplication(unwrap(result)) : { id: applicationId, status: decision };
    },
    formatDate,
    escapeHtml,
    initials,
    renderAvatar(candidate, className = '') {
      const name = escapeHtml(candidate.nome);
      const avatar = escapeHtml(candidate.avatar || fallbackAvatar(name, candidate.id));
      return `<span class="person-avatar ${className}"><img src="${avatar}" alt="" loading="lazy" onerror="this.hidden=true;this.nextElementSibling.hidden=false"><span class="person-avatar__initials" hidden>${initials(name)}</span></span>`;
    }
  };
})();