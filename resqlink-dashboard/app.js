/* ============================================================
   ResQLink Command Center — Interactive Logic
   Handles: card selection, filters, keyboard navigation, 
   simulated real-time updates, sidebar tooltips
   ============================================================ */

(function () {
  'use strict';

  // --- INCIDENT DATA ---
  const incidents = [
    { id: 'SOS-0847', severity: 'critical', title: 'Medical Emergency — Room 412', time: 158, acknowledged: false },
    { id: 'SOS-0852', severity: 'critical', title: 'Fire Alarm — Floor 6 East', time: 47, acknowledged: false },
    { id: 'SOS-0855', severity: 'critical', title: 'SOS Panic — Pool Area', time: 12, acknowledged: false },
    { id: 'INC-0843', severity: 'high', title: 'Unauthorized Access — Staff Area B2', time: 480, acknowledged: false },
    { id: 'INC-0841', severity: 'high', title: 'Aggressive Guest — Lobby Bar', time: 720, acknowledged: false },
    { id: 'INC-0839', severity: 'medium', title: 'Noise Complaint — Room 307', time: 1080, acknowledged: false },
    { id: 'INC-0836', severity: 'medium', title: 'Water Leak Detected — Room 512', time: 1440, acknowledged: false },
  ];

  // --- CARD SELECTION ---
  const incidentCards = document.querySelectorAll('.incident-card');

  incidentCards.forEach(card => {
    card.addEventListener('click', () => {
      incidentCards.forEach(c => c.classList.remove('incident-card--selected'));
      card.classList.add('incident-card--selected');
    });
  });

  // --- FILTER PILLS ---
  const filterPills = document.querySelectorAll('.filter-pill');
  const cardContainer = document.getElementById('incident-cards');

  filterPills.forEach(pill => {
    pill.addEventListener('click', () => {
      filterPills.forEach(p => p.classList.remove('filter-pill--active'));
      pill.classList.add('filter-pill--active');

      const filter = pill.textContent.trim().toLowerCase();
      const cards = cardContainer.querySelectorAll('.incident-card');

      cards.forEach(card => {
        if (filter === 'all') {
          card.style.display = '';
        } else {
          const isSeverity = card.classList.contains(`incident-card--${filter}`);
          card.style.display = isSeverity ? '' : 'none';
        }
      });
    });
  });

  // --- KEYBOARD NAVIGATION ---
  document.addEventListener('keydown', (e) => {
    // "/" to focus search
    if (e.key === '/') {
      const searchInput = document.getElementById('search-input');
      if (document.activeElement !== searchInput) {
        e.preventDefault();
        searchInput.focus();
      }
    }

    // Escape to blur
    if (e.key === 'Escape') {
      document.activeElement.blur();
    }

    // Arrow keys for incident navigation
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      const selected = document.querySelector('.incident-card--selected');
      if (!selected) return;

      const cards = Array.from(document.querySelectorAll('.incident-card:not([style*="display: none"])'));
      const currentIndex = cards.indexOf(selected);

      let nextIndex;
      if (e.key === 'ArrowDown') {
        nextIndex = Math.min(currentIndex + 1, cards.length - 1);
      } else {
        nextIndex = Math.max(currentIndex - 1, 0);
      }

      if (nextIndex !== currentIndex) {
        e.preventDefault();
        cards.forEach(c => c.classList.remove('incident-card--selected'));
        cards[nextIndex].classList.add('incident-card--selected');
        cards[nextIndex].scrollIntoView({ block: 'nearest', behavior: 'smooth' });
      }
    }
  });

  // --- SIDEBAR ACTIVE STATE ---
  const sidebarItems = document.querySelectorAll('.sidebar__item');
  sidebarItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      sidebarItems.forEach(i => i.classList.remove('sidebar__item--active'));
      item.classList.add('sidebar__item--active');
    });
  });

  // --- BUTTON INTERACTIONS ---
  // Acknowledge buttons
  document.querySelectorAll('[id^="btn-ack-"]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const card = btn.closest('.incident-card');
      btn.textContent = '✓ Acknowledged';
      btn.disabled = true;
      btn.classList.remove('btn--primary', 'btn--danger');
      btn.classList.add('btn--ghost');
      btn.style.color = 'var(--severity-resolved)';
      btn.style.borderColor = 'rgba(34, 197, 94, 0.25)';
    });
  });

  // Apply AI suggestions
  const applyAiBtn = document.getElementById('btn-apply-ai');
  if (applyAiBtn) {
    applyAiBtn.addEventListener('click', () => {
      applyAiBtn.textContent = '✓ Applied';
      applyAiBtn.disabled = true;
      applyAiBtn.classList.remove('btn--primary');
      applyAiBtn.classList.add('btn--ghost');
      applyAiBtn.style.color = 'var(--severity-resolved)';

      // Add timeline entry
      const timelineItems = document.querySelector('.timeline__items');
      if (timelineItems) {
        const newEntry = document.createElement('div');
        newEntry.className = 'timeline__item';
        newEntry.innerHTML = `
          <div class="timeline__dot timeline__dot--ai"></div>
          <div class="timeline__content">
            <span class="timeline__event">🤖 AI recommendations applied by operator</span>
            <span class="timeline__time">just now</span>
          </div>
        `;
        timelineItems.insertBefore(newEntry, timelineItems.firstChild);
      }
    });
  }

  // Resolve button
  const resolveBtn = document.getElementById('btn-resolve');
  if (resolveBtn) {
    resolveBtn.addEventListener('click', () => {
      const selected = document.querySelector('.incident-card--selected');
      if (selected) {
        selected.classList.remove('incident-card--critical', 'incident-card--high', 'incident-card--medium');
        selected.style.borderLeftColor = 'var(--severity-resolved)';
        selected.style.background = 'var(--severity-resolved-bg)';

        const badge = selected.querySelector('.severity-badge');
        if (badge) {
          badge.className = 'severity-badge severity-badge--resolved';
          badge.querySelector('.severity-badge__shape').textContent = '✓';
          badge.querySelector('.severity-badge__text').textContent = 'RESOLVED';
        }
      }
    });
  }

  // --- SIMULATED REAL-TIME TIMER UPDATES ---
  function formatTime(seconds) {
    if (seconds < 60) return `${seconds}s ago`;
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    return `${Math.floor(seconds / 3600)}h ago`;
  }

  setInterval(() => {
    incidents.forEach(inc => {
      inc.time += 1;
    });

    // Update timestamps on visible cards
    const cards = document.querySelectorAll('.incident-card');
    cards.forEach((card, index) => {
      if (incidents[index]) {
        const timeEl = card.querySelector('.incident-card__time');
        if (timeEl) {
          timeEl.textContent = formatTime(incidents[index].time);
        }
      }
    });

    // Update detail panel time
    const detailTime = document.querySelector('.detail-header__meta-item');
    if (detailTime && incidents[0]) {
      const svg = detailTime.querySelector('svg');
      if (svg) {
        detailTime.innerHTML = '';
        detailTime.appendChild(svg);
        detailTime.appendChild(document.createTextNode(` Started ${formatTime(incidents[0].time)}`));
      }
    }
  }, 1000);

  // --- SIMULATED STATS UPDATE ---
  const statActive = document.querySelector('#stat-active .stat__value');
  const statToday = document.querySelector('#stat-today .stat__value');

  setInterval(() => {
    // Random small fluctuations for realism
    if (Math.random() > 0.9 && statActive) {
      const current = parseInt(statActive.textContent);
      statActive.textContent = current + (Math.random() > 0.5 ? 1 : -1);
    }
    if (Math.random() > 0.95 && statToday) {
      const current = parseInt(statToday.textContent);
      statToday.textContent = current + 1;
    }
  }, 5000);

  // --- CONNECTION STATUS SIMULATION ---
  const connectionDot = document.querySelector('#btn-connection .status-dot');
  const connectionStatus = document.querySelector('.statusbar__item:first-child');

  setInterval(() => {
    // Simulate very rare connection blips
    if (Math.random() > 0.995 && connectionDot) {
      connectionDot.classList.remove('status-dot--online');
      connectionDot.classList.add('status-dot--busy');
      setTimeout(() => {
        connectionDot.classList.remove('status-dot--busy');
        connectionDot.classList.add('status-dot--online');
      }, 2000);
    }
  }, 1000);

  // --- SEARCH FUNCTIONALITY ---
  const searchInput = document.getElementById('search-input');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase().trim();
      const cards = document.querySelectorAll('.incident-card');

      cards.forEach(card => {
        if (!query) {
          card.style.display = '';
          return;
        }
        const text = card.textContent.toLowerCase();
        card.style.display = text.includes(query) ? '' : 'none';
      });
    });
  }

  console.log('%c[ResQLink] Command Center initialized', 'color: #3B82F6; font-weight: bold;');
  console.log('%c[ResQLink] Press "/" to search, ↑↓ to navigate incidents', 'color: #8a8f98;');
})();
