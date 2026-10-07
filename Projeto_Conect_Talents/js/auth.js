(function () {
  const TOKEN_KEY = 'conectatalentos_token';
  const COMPANY_KEY = 'conectatalentos_empresa';
  window.API_BASE_URL = window.API_BASE_URL || 'http://localhost:5000/api';

  function saveSession(response) {
    if (!response || !response.token || !response.empresa) {
      throw new Error('A resposta de autenticação da API está incompleta.');
    }
    localStorage.setItem(TOKEN_KEY, response.token);
    localStorage.setItem(COMPANY_KEY, JSON.stringify(response.empresa));
  }

  async function submit(path, data) {
    try {
      const response = await fetch(`${window.API_BASE_URL.replace(/\/+$/, '')}${path}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      const result = await response.json().catch(() => null);
      if (!response.ok) {
        return {
          success: false,
          message: result?.message || result?.title || result?.erro || 'Não foi possível concluir a solicitação.'
        };
      }
      saveSession(result);
      return { success: true, data: result };
    } catch (error) {
      return {
        success: false,
        message: error instanceof TypeError || /failed to fetch|networkerror|load failed/i.test(error.message || '')
          ? 'Não foi possível conectar à API. Tente novamente.'
          : error.message || 'Não foi possível concluir a solicitação.'
      };
    }
  }

  window.AuthData = {
    login(email, senha) {
      return submit('/auth/empresa/login', { email, senha });
    },
    registrar(dadosEmpresa) {
      return submit('/auth/empresa/registrar', dadosEmpresa);
    },
    logout() {
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem(COMPANY_KEY);
      window.location.replace('login.html');
    },
    getToken() {
      return localStorage.getItem(TOKEN_KEY);
    },
    getEmpresaLogada() {
      try {
        return JSON.parse(localStorage.getItem(COMPANY_KEY) || 'null');
      } catch {
        localStorage.removeItem(COMPANY_KEY);
        return null;
      }
    },
    isAutenticado() {
      return Boolean(localStorage.getItem(TOKEN_KEY));
    }
  };
})();