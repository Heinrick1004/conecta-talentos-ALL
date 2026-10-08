(function () {
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function animateThemeChange(previousColors) {
    if (!window.gsap || reduceMotion) return;

    previousColors.forEach(entry => {
      const nextStyle = getComputedStyle(entry.element);
      window.gsap.fromTo(entry.element, {
        backgroundColor: entry.backgroundColor,
        color: entry.color
      }, {
        backgroundColor: nextStyle.backgroundColor,
        color: nextStyle.color,
        duration: 0.35,
        ease: 'power1.out',
        clearProps: 'backgroundColor,color'
      });
    });
  }

  function animateCarousel(element) {
    if (!window.gsap || reduceMotion || !element) return;

    window.gsap.fromTo(element.querySelector('.treino-hero__content'), {
      autoAlpha: 0,
      x: 8
    }, {
      autoAlpha: 1,
      x: 0,
      duration: 0.3,
      ease: 'power2.out'
    });
  }

  window.ConectaAnimations = { animateThemeChange, animateCarousel };

  if (!window.gsap || reduceMotion) return;

  const pageContent = document.querySelector('.page-content');
  if (pageContent) {
    window.gsap.from(pageContent.children, {
      autoAlpha: 0,
      y: 12,
      duration: 0.38,
      stagger: 0.06,
      ease: 'power2.out',
      clearProps: 'opacity,visibility,transform'
    });
  }

  const loginPanels = document.querySelectorAll('.login-left, .login-right');
  if (loginPanels.length) {
    window.gsap.from(loginPanels, {
      autoAlpha: 0,
      y: 10,
      duration: 0.4,
      stagger: 0.08,
      ease: 'power2.out',
      clearProps: 'opacity,visibility,transform'
    });
  }

  const listItems = document.querySelectorAll(
    '.stat-card, .vaga-card, .candidato-card, .treino-card, .most-viewed-item, .job-row, .application-card, .profile-application'
  );
  if (listItems.length) {
    window.gsap.from(listItems, {
      autoAlpha: 0,
      y: 10,
      duration: 0.32,
      stagger: 0.045,
      delay: 0.12,
      ease: 'power2.out',
      clearProps: 'opacity,visibility,transform'
    });
  }

  document.querySelectorAll(
    '.stat-card, .vaga-card, .candidato-card, .treino-card, .job-row, .application-card, .profile-application, .promo-banner, .btn, .filter-btn, .sort-btn, .chevron-btn, .top-header__theme-toggle'
  ).forEach(element => {
    element.addEventListener('pointerenter', () => {
      window.gsap.to(element, {
        y: -2,
        scale: 1.01,
        duration: 0.2,
        ease: 'power1.out',
        overwrite: 'auto'
      });
    });
    element.addEventListener('pointerleave', () => {
      window.gsap.to(element, {
        y: 0,
        scale: 1,
        duration: 0.2,
        ease: 'power1.out',
        overwrite: 'auto'
      });
    });
  });
})();
