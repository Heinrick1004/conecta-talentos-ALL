/**
 * ConectaTalentos — Componentes compartilhados
 * Renderiza sidebar, header e utilitários reutilizáveis.
 */

/* --- Ícones SVG inline --- */
const ICONS = {
  dashboard: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>`,
  vagas: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/></svg>`,
  candidatos: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>`,
  treinamentos: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c0 1.1 2.7 2 6 2s6-.9 6-2v-5"/></svg>`,
  bell: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>`,
  chevronDown: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>`,
  chevronRight: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>`,
  search: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>`,
  filter: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>`,
  mapPin: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>`,
  briefcase: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/></svg>`,
  building: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01M16 6h.01M12 6h.01M12 10h.01M12 14h.01M16 10h.01M16 14h.01M8 10h.01M8 14h.01"/></svg>`,
  arrowUp: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="19" x2="12" y2="5"/><polyline points="5 12 12 5 19 12"/></svg>`,
  flame: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/></svg>`,
  lightbulb: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18h6"/><path d="M10 22h4"/><path d="M15.09 14c.18-.98.65-1.74 1.41-2.5A4.65 4.65 0 0 0 18 8 6 6 0 0 0 6 8c0 1 .23 2.23 1.5 3.5A4.61 4.61 0 0 1 8.91 14"/></svg>`,
  users: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>`,
  menu: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>`,
  sort: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="4" y1="6" x2="20" y2="6"/><line x1="4" y1="12" x2="14" y2="12"/><line x1="4" y1="18" x2="8" y2="18"/></svg>`,
  moon: `<svg class="icon-moon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>`,
  sun: `<svg class="icon-sun" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>`
};

/* Ícones de vagas por tipo */
const JOB_ICONS = {
  code: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>`,
  chart: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>`,
  users: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>`,
  megaphone: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/></svg>`,
  headset: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18v-6a9 9 0 0 1 18 0v6"/><path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z"/></svg>`
};

/* Logo SVG */
const LOGO_SVG = `
<svg class="sidebar__logo-icon" viewBox="0 0 44 44" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="14" cy="22" r="10" fill="#E8541D" opacity="0.85"/>
  <circle cx="30" cy="22" r="10" fill="#FF6B2C"/>
  <path d="M14 12 Q22 22 14 32" stroke="white" stroke-width="2" fill="none" opacity="0.5"/>
  <path d="M30 12 Q22 22 30 32" stroke="white" stroke-width="2" fill="none" opacity="0.5"/>
</svg>`;

/* Ilustração sidebar (pessoas diversas) */
const SIDEBAR_ILLUSTRATION = `
<svg class="sidebar__banner-illustration" viewBox="0 0 120 80" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="30" cy="35" r="14" fill="#C48A62"/>
  <ellipse cx="30" cy="62" rx="16" ry="12" fill="#E8541D"/>
  <circle cx="55" cy="30" r="12" fill="#E8B48A"/>
  <ellipse cx="55" cy="58" rx="14" ry="10" fill="#2A2A2A"/>
  <circle cx="80" cy="33" r="13" fill="#8D5A3A"/>
  <ellipse cx="80" cy="60" rx="15" ry="11" fill="#FF6B2C"/>
  <circle cx="100" cy="28" r="10" fill="#F3D2B3"/>
  <ellipse cx="100" cy="52" rx="12" ry="9" fill="#3A3A3A"/>
</svg>`;

/* Textos do banner lateral por página */
const SIDEBAR_BANNERS = {
  dashboard: {
    title: 'Juntos por um futuro mais inclusivo',
    text: 'Mais oportunidades, mais diversidade, mais talentos.'
  },
  vagas: {
    title: 'Juntos por um futuro mais inclusivo',
    text: 'Mais oportunidades, mais diversidade, mais talentos.'
  },
  candidatos: {
    title: 'Talento também é diversidade',
    text: 'Mais oportunidades, mais histórias, mais conquistas.'
  },
  treinamentos: {
    title: 'Conhecimento também é uma oportunidade.',
    text: 'Capacite sua equipe, construa um futuro mais inclusivo.'
  }
};

/* --- Navegação --- */
const NAV_ITEMS = [
  { id: 'dashboard', label: 'Dashboard', href: 'index.html', icon: 'dashboard' },
  { id: 'vagas', label: 'Vagas', href: 'vagas.html', icon: 'vagas' },
  { id: 'candidatos', label: 'Candidatos', href: 'candidatos.html', icon: 'candidatos' },
  { id: 'treinamentos', label: 'Treinamentos', href: 'treinamentos.html', icon: 'treinamentos' }
];

/**
 * Renderiza a sidebar completa
 * @param {string} activePage - ID da página ativa
 */
function renderSidebar(activePage) {
  const banner = SIDEBAR_BANNERS[activePage] || SIDEBAR_BANNERS.dashboard;

  const navHTML = NAV_ITEMS.map(item => `
    <a href="${item.href}" class="nav-item ${item.id === activePage ? 'active' : ''}">
      ${ICONS[item.icon]}
      <span>${item.label}</span>
    </a>
  `).join('');

  return `
    <aside class="sidebar" id="sidebar">
      <div class="sidebar__logo">
        ${LOGO_SVG}
        <div class="sidebar__logo-text">
          <div class="sidebar__brand">
            <span class="brand-conecta">Conecta</span><span class="brand-talentos">Talentos</span>
          </div>
          <span class="sidebar__slogan">Pessoas certas. Grandes resultados.</span>
        </div>
      </div>

      <nav class="sidebar__nav" aria-label="Menu principal">
        ${navHTML}
      </nav>

      <div class="sidebar__banner">
        <p class="sidebar__banner-title">${banner.title}</p>
        <p class="sidebar__banner-text">${banner.text}</p>
        ${SIDEBAR_ILLUSTRATION}
      </div>
    </aside>
    <div class="sidebar-overlay" id="sidebarOverlay"></div>
  `;
}

/**
 * Renderiza o header superior
 */
function renderHeader() {
  const isDark = window.ConectaTheme && window.ConectaTheme.getTheme() === 'dark';
  const themeLabel = isDark ? 'Ativar tema claro' : 'Ativar tema escuro';
  const company = AuthData.getEmpresaLogada() || {};
  const companyName = String(company.nomeFantasia || 'Empresa').replace(/[&<>"']/g, character => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  })[character]);
  const companyInitials = companyName.trim().split(/\s+/).slice(0, 2).map(part => part.charAt(0).toUpperCase()).join('');

  return `
    <header class="top-header">
      <button class="mobile-menu-btn" id="mobileMenuBtn" aria-label="Abrir menu">
        ${ICONS.menu}
      </button>
      <div style="flex:1"></div>
      <button
        class="top-header__theme-toggle"
        id="themeToggleBtn"
        type="button"
        aria-label="${themeLabel}"
        title="${themeLabel}"
      >
        ${ICONS.moon}
        ${ICONS.sun}
      </button>
      <div class="top-header__account" id="accountMenuContainer">
        <button
          class="top-header__profile"
          id="accountMenuToggle"
          type="button"
          aria-expanded="false"
          aria-controls="accountMenu"
          aria-label="Abrir menu da conta"
        >
          <span class="top-header__avatar">${companyInitials}</span>
          <span class="top-header__company">${companyName}</span>
          <span class="top-header__chevron">${ICONS.chevronDown}</span>
        </button>
        <nav class="account-menu" id="accountMenu" aria-label="Menu da conta" hidden>
          <a href="login.html" class="account-menu__item account-menu__item--logout" data-logout>Sair</a>
        </nav>
      </div>
    </header>
  `;
}

/**
 * Vincula o botão de alternância de tema no header
 */
function initThemeToggle() {
  const btn = document.getElementById('themeToggleBtn');
  if (!btn || !window.ConectaTheme) return;

  btn.addEventListener('click', () => {
    const next = window.ConectaTheme.toggleTheme();
    const label = next === 'dark' ? 'Ativar tema claro' : 'Ativar tema escuro';
    btn.setAttribute('aria-label', label);
    btn.setAttribute('title', label);
  });
}

function initAccountMenu() {
  const container = document.getElementById('accountMenuContainer');
  const toggle = document.getElementById('accountMenuToggle');
  const menu = document.getElementById('accountMenu');
  if (!container || !toggle || !menu) return;

  const closeMenu = () => {
    menu.hidden = true;
    toggle.setAttribute('aria-expanded', 'false');
  };

  toggle.addEventListener('click', () => {
    menu.hidden = !menu.hidden;
    toggle.setAttribute('aria-expanded', String(!menu.hidden));
  });

  document.addEventListener('click', event => {
    if (!container.contains(event.target)) closeMenu();
  });

  document.addEventListener('keydown', event => {
    if (event.key === 'Escape' && !menu.hidden) {
      closeMenu();
      toggle.focus();
    }
  });

  menu.addEventListener('click', event => {
    const logout = event.target.closest('[data-logout]');
    if (logout) {
      event.preventDefault();
      AuthData.logout();
      return;
    }
    if (event.target.closest('a')) closeMenu();
  });

  container.addEventListener('focusout', event => {
    if (!container.contains(event.relatedTarget)) closeMenu();
  });
}

/**
 * Retorna HTML do ícone de vaga colorido
 */
function renderJobIcon(vaga) {
  const iconHTML = JOB_ICONS[vaga.icone] || JOB_ICONS.code;
  return `<div class="job-icon job-icon--${vaga.cor}">${iconHTML}</div>`;
}

/**
 * Retorna badge de candidaturas
 */
function renderCandidaturasBadge(vaga) {
  return `<span class="badge badge--${vaga.cor}">${vaga.candidaturas} candidaturas</span>`;
}

function renderJobStatus(status) {
  const statusClass = status === 'Encerrada' ? 'closed' : 'open';
  return `<span class="badge job-status job-status--${statusClass}">${status}</span>`;
}

/**
 * Retorna badge de status do candidato
 */
function renderStatusBadge(status, label) {
  const colorMap = {
    disponivel: 'green',
    avaliacao: 'blue',
    indisponivel: 'purple'
  };
  const cor = colorMap[status] || 'gray';
  return `<span class="badge badge--${cor}"><span class="status-dot status-dot--${cor}"></span>${label}</span>`;
}

/**
 * Inicializa layout compartilhado (sidebar + menu mobile)
 * @param {string} activePage
 */
function initLayout(activePage) {
  const sidebarContainer = document.getElementById('sidebar-container');
  if (sidebarContainer) {
    sidebarContainer.innerHTML = renderSidebar(activePage);
  }

  const headerContainer = document.getElementById('header-container');
  if (headerContainer) {
    headerContainer.innerHTML = renderHeader();
  }

  /* Menu mobile */
  const menuBtn = document.getElementById('mobileMenuBtn');
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebarOverlay');

  if (menuBtn && sidebar && overlay) {
    menuBtn.addEventListener('click', () => {
      sidebar.classList.toggle('open');
      overlay.classList.toggle('active');
    });

    overlay.addEventListener('click', () => {
      sidebar.classList.remove('open');
      overlay.classList.remove('active');
    });
  }

  initThemeToggle();
  initAccountMenu();
}
