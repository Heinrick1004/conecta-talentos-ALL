/**
 * ConectaTalentos — Gerenciamento de tema (light / dark)
 * Carregado no <head> para evitar flash de tema incorreto.
 */
(function () {
  const STORAGE_KEY = 'conectatalentos-theme';

  function getPreferredTheme() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved === 'dark' || saved === 'light') return saved;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function captureThemeColors() {
    const surfaces = document.querySelectorAll(
      'body, .sidebar, .top-header, .card, .hero-card, .promo-banner, .treino-hero, .login-shell, .login-left, .login-right, input, .filter-btn, .sort-btn'
    );

    return Array.from(surfaces, element => {
      const style = getComputedStyle(element);
      return {
        element,
        backgroundColor: style.backgroundColor,
        color: style.color
      };
    });
  }

  function applyTheme(theme, animate = false) {
    const previousColors = animate ? captureThemeColors() : [];
    document.documentElement.setAttribute('data-theme', theme);
    if (previousColors.length && window.ConectaAnimations) {
      window.ConectaAnimations.animateThemeChange(previousColors);
    }
  }

  applyTheme(getPreferredTheme());

  window.ConectaTheme = {
    STORAGE_KEY,
    getTheme: () => document.documentElement.getAttribute('data-theme') || 'light',
    setTheme(theme) {
      applyTheme(theme, true);
      localStorage.setItem(STORAGE_KEY, theme);
    },
    toggleTheme() {
      const next = this.getTheme() === 'dark' ? 'light' : 'dark';
      this.setTheme(next);
      return next;
    }
  };
})();
