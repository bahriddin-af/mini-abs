/* Mini-ABS: sahifadagi kichik interaktivlik. Barcha ma'lumot server (JSP + PL/SQL) tomonida. */
(function () {
  'use strict';
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const app = $('#app');

  /* ---------- Sidebar: accordion, yig'ish, mobil menyu ---------- */
  $$('.group > button').forEach(b => b.addEventListener('click', () => {
    if (app.classList.contains('collapsed') && innerWidth > 900) {
      const link = b.parentElement.querySelector('.sub a');
      if (link) location.href = link.href;
      return;
    }
    const open = b.parentElement.classList.toggle('open');
    b.setAttribute('aria-expanded', open);
  }));
  try { if (localStorage.getItem('abs-collapsed') === '1' && innerWidth > 900) app.classList.add('collapsed'); } catch (e) {}
  const burger = $('#burger');
  if (burger) burger.addEventListener('click', () => {
    if (innerWidth <= 900) { app.classList.toggle('mobile-open'); return; }
    const c = app.classList.toggle('collapsed');
    try { localStorage.setItem('abs-collapsed', c ? '1' : '0'); } catch (e) {}
  });
  const backdrop = $('#backdrop');
  if (backdrop) backdrop.addEventListener('click', () => app.classList.remove('mobile-open'));

  /* ---------- Mavzu (light / dark) ---------- */
  const themeBtn = $('#themeBtn');
  const syncThemeIcon = () => {
    const dark = (document.documentElement.dataset.theme || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')) === 'dark';
    if (themeBtn) $('use', themeBtn).setAttribute('href', dark ? '#i-sun' : '#i-moon');
    return dark;
  };
  if (themeBtn) {
    syncThemeIcon();
    themeBtn.addEventListener('click', () => {
      const t = syncThemeIcon() ? 'light' : 'dark';
      document.documentElement.dataset.theme = t;
      try { localStorage.setItem('abs-theme', t); } catch (e) {}
      syncThemeIcon();
    });
  }

  /* ---------- Profil menyusi ---------- */
  const profileBtn = $('#profileBtn'), profileMenu = $('#profileMenu');
  if (profileBtn) {
    profileBtn.addEventListener('click', e => {
      e.stopPropagation();
      profileMenu.hidden = !profileMenu.hidden;
      profileBtn.setAttribute('aria-expanded', !profileMenu.hidden);
    });
    document.addEventListener('click', e => { if (!e.target.closest('#profileMenu')) profileMenu.hidden = true; });
  }

  /* ---------- Modal oynalar ---------- */
  function openModal(m) {
    $$('.overlay').forEach(o => o.hidden = true);
    m.hidden = false;
    const f = m.querySelector('input:not([type=hidden]):not([type=radio]), select');
    if (f) setTimeout(() => f.focus(), 30);
  }
  function closeModals() { $$('.overlay').forEach(o => o.hidden = true); }
  document.addEventListener('click', e => {
    const o = e.target.closest('[data-open]');
    if (o) { openModal($('#' + o.dataset.open)); return; }
    if (e.target.closest('[data-close]') || e.target.classList.contains('overlay')) closeModals();
  });
  $$('.overlay[data-autoopen]').forEach(openModal);

  /* ---------- Tasdiqlash oynasi: data-confirm tugmalari ---------- */
  const cf = $('#confirmForm');
  document.addEventListener('click', e => {
    const b = e.target.closest('[data-confirm]');
    if (!b || !cf) return;
    const d = b.dataset;
    cf.action = d.action;
    cf.querySelector('[name=back]').value = location.pathname + location.search;
    $('#cfTitle').textContent = d.title;
    $('#cfText').textContent = d.text;
    const fields = $('#cfFields');
    fields.innerHTML = '';
    Object.keys(d).filter(k => /^f[A-Z]/.test(k)).forEach(k => {
      const inp = document.createElement('input');
      inp.type = 'hidden';
      inp.name = k.charAt(1).toLowerCase() + k.slice(2);
      inp.value = d[k];
      fields.appendChild(inp);
    });
    const needReason = d.reason === 'true';
    $('#cfReasonBox').hidden = !needReason;
    $('#cfReason').disabled = !needReason;
    const ok = $('#cfOk');
    ok.className = 'btn ' + (d.danger === 'true' ? 'btn-red' : 'btn-primary');
    ok.textContent = d.ok;
    openModal($('#confirmModal'));
  });

  /* ---------- Mijoz formasi: yangi / tahrirlash ---------- */
  const clientForm = $('#clientForm');
  function syncClientType() {
    if (!clientForm) return;
    const y = clientForm.querySelector('[name=type]:checked').value === 'Y';
    $('#cmNameLbl').innerHTML = (y ? 'Tashkilot nomi' : 'F.I.Sh.') + ' <span class="req">*</span>';
    $('#cmCodeLbl').innerHTML = (y ? 'INN' : 'PINFL') + ' <span class="req">*</span>';
    const code = $('#cmCode');
    code.maxLength = y ? 9 : 14;
    code.placeholder = y ? '9 ta raqam' : '14 ta raqam';
    code.pattern = y ? '[0-9]{9}' : '[0-9]{14}';
    $('#cmName').placeholder = y ? '"Kompaniya nomi" MChJ' : 'Familiya Ism Otasining ismi';
  }
  if (clientForm) {
    $$('[name=type]', clientForm).forEach(r => r.addEventListener('change', syncClientType));
    syncClientType();
    const fill = (v) => {
      clientForm.querySelector('[name=id]').value = v.id || '';
      clientForm.querySelector(`[name=type][value=${v.type || 'J'}]`).checked = true;
      $$('[name=type]', clientForm).forEach(r => r.disabled = !!v.id);
      $('#cmName').value = v.name || '';
      $('#cmCode').value = v.tax || '';
      $('#cmPhone').value = v.phone || '';
      $('#cmAddr').value = v.address || '';
      $('#cmTitle').textContent = v.id ? 'Mijozni tahrirlash' : 'Yangi mijoz';
      const err = clientForm.querySelector('.alert'); if (err) err.remove();
      syncClientType();
      openModal($('#clientModal'));
    };
    $$('[data-new-client]').forEach(b => b.addEventListener('click', () => fill({})));
    document.addEventListener('click', e => { const b = e.target.closest('[data-edit-client]'); if (b) fill(b.dataset); });
    // disabled radio formaga yuborilmaydi; tahrirlashda tur o'zgarmaydi, server uni bazadan oladi
    if (clientForm.querySelector('[name=id]').value) $$('[name=type]', clientForm).forEach(r => r.disabled = true);
  }

  /* ---------- Ro'yxatlar: filtr paneli, jonli qidiruv, sahifa hajmi ---------- */
  $$('[data-filter-toggle]').forEach(b => b.addEventListener('click', () => {
    const p = b.closest('form').querySelector('[data-filters]');
    p.hidden = !p.hidden;
    b.setAttribute('aria-pressed', !p.hidden);
  }));
  $$('[data-autosubmit]').forEach(inp => {
    let timer;
    inp.addEventListener('input', () => {
      clearTimeout(timer);
      timer = setTimeout(() => inp.form.submit(), 450);
    });
    // fokus qayta tiklanganda kursor oxirida tursin
    if (inp.value && document.activeElement !== inp && new URLSearchParams(location.search).has('q')) {
      inp.focus();
      inp.setSelectionRange(inp.value.length, inp.value.length);
    }
  });
  $$('[data-goto-size]').forEach(s => s.addEventListener('change', () => { location.href = s.value; }));

  /* ---------- Pul o'tkazish formasi ---------- */
  const trFrom = $('[data-reload-from]');
  if (trFrom) trFrom.addEventListener('change', () => {
    location.href = APP.ctx + '/transfer?from=' + encodeURIComponent(trFrom.value);
  });
  const trTo = $('#trTo'), owner = $('#trOwner');
  if (trTo && owner) {
    let seq = 0;
    const lookup = () => {
      const no = trTo.value.replace(/\D/g, '');
      if (no.length !== 20) { owner.className = 'owner'; owner.textContent = '20 xonali hisob raqamini kiriting'; return; }
      const my = ++seq;
      fetch(APP.ctx + '/api/account-owner?no=' + no, {credentials: 'same-origin'})
        .then(r => r.json())
        .then(d => {
          if (my !== seq) return;
          owner.className = 'owner' + (d.name ? '' : ' bad');
          owner.textContent = d.name ? 'Hisob egasi: ' + d.name : 'Bunday hisob topilmadi';
        })
        .catch(() => { owner.textContent = ''; });
    };
    trTo.addEventListener('input', lookup);
    lookup();
  }
  const trAmt = $('#trAmt');
  if (trAmt) trAmt.addEventListener('blur', () => {
    const n = Number(trAmt.value.replace(/\s/g, '').replace(',', '.'));
    if (n > 0) trAmt.value = n.toLocaleString('ru-RU', {maximumFractionDigits: 2}).replace(/[  ]/g, ' ');
  });
  const trForm = $('#trForm');
  if (trForm) trForm.addEventListener('submit', () => {
    const btn = trForm.querySelector('[type=submit]');
    btn.disabled = true;   // ikki marta bosilib, ikki o'tkazma ketmasligi uchun
  });

  /* ---------- Toastlar, yordam, klaviatura ---------- */
  $$('.toast').forEach(t => setTimeout(() => t.remove(), 4000));
  const fab = $('#fab'), help = $('#helpPanel');
  if (fab) fab.addEventListener('click', () => { help.hidden = !help.hidden; });
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') { closeModals(); if (help) help.hidden = true; return; }
    if ($$('.overlay').some(o => !o.hidden)) return;
    if (e.key === '/' && !/INPUT|SELECT|TEXTAREA/.test(document.activeElement.tagName)) {
      const s = $('[data-autosubmit]'); if (s) { e.preventDefault(); s.focus(); }
    }
    if (e.altKey && e.key.toLowerCase() === 't') { e.preventDefault(); location.href = APP.ctx + '/transfer'; }
  });
})();
