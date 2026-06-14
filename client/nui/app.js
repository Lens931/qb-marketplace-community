(() => {
  const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'qb-marketplace';
  const DEMO = typeof GetParentResourceName !== 'function' || new URLSearchParams(window.location.search).has('demo');

  const state = {
    config: {},
    locale: 'fr',
    dict: window.NUI_LOCALES.fr,
    activeTab: 'sell',
    inventory: [],
    offers: [],
    myListings: [],
    history: [],
    selectedItem: null,
    selectedHistory: new Set(),
    filters: {
      inventorySearch: '',
      inventoryCategory: 'all',
      offersSearch: '',
      offersCategory: 'all',
      offersSort: 'date-desc',
      mineStatus: 'all'
    },
    pending: false
  };

  const $ = (selector) => document.querySelector(selector);
  const $$ = (selector) => Array.from(document.querySelectorAll(selector));

  const elements = {
    app: $('#app'),
    marketplace: $('#marketplace'),
    loader: $('#loader'),
    toastStack: $('#toast-stack'),
    inventoryGrid: $('#inventory-grid'),
    inventoryEmpty: $('#inventory-empty'),
    offersGrid: $('#offers-grid'),
    offersEmpty: $('#offers-empty'),
    mineGrid: $('#mine-grid'),
    mineEmpty: $('#mine-empty'),
    historyList: $('#history-list'),
    historyEmpty: $('#history-empty'),
    statOffers: $('#stat-offers'),
    statEarnings: $('#stat-earnings'),
    selectedLabel: $('#selected-item-label'),
    selectedPreview: $('#selected-preview'),
    sellQuantity: $('#sell-quantity'),
    sellPrice: $('#sell-price'),
    createButton: $('#create-listing-btn'),
    summaryGross: $('#summary-gross'),
    summaryTax: $('#summary-tax'),
    summaryNet: $('#summary-net'),
    configList: $('#config-list'),
    modal: $('#confirm-modal'),
    confirmTitle: $('#confirm-title'),
    confirmBody: $('#confirm-body'),
    confirmCancel: $('#confirm-cancel'),
    confirmAccept: $('#confirm-accept')
  };

  function t(key, params = {}) {
    let value = state.dict[key] || key;
    Object.entries(params).forEach(([name, replacement]) => {
      value = value.split(`{${name}}`).join(String(replacement));
    });
    return value;
  }

  function setText(node, value) {
    if (node) node.textContent = value;
  }

  function money(value) {
    const amount = Number(value || 0).toLocaleString(state.locale === 'fr' ? 'fr-FR' : 'en-US');
    return `${state.config.currency || '$'}${amount}`;
  }

  function taxFor(amount) {
    const tax = state.config.tax || {};
    if (!tax.enabled) return 0;

    const raw = Number(amount || 0) * (Number(tax.percentage || 0) / 100);
    if (tax.round === 'ceil') return Math.ceil(raw);
    if (tax.round === 'nearest') return Math.floor(raw + 0.5);
    return Math.floor(raw);
  }

  function dateLabel(value) {
    if (!value) return t('time.noExpiration');
    const date = new Date(String(value).replace(' ', 'T'));
    if (Number.isNaN(date.getTime())) return String(value);

    return new Intl.DateTimeFormat(state.locale === 'fr' ? 'fr-FR' : 'en-US', {
      month: 'short',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date);
  }

  function itemImage(item) {
    if (item.image) return item.image;
    if (item.item_image) return item.item_image;
    const pattern = state.config.imagePath;
    return pattern ? pattern.replace('%s', item.name || item.item_name) : '';
  }

  function createMedia(item) {
    const wrap = document.createElement('div');
    wrap.className = 'item-media';

    const image = itemImage(item);
    if (image) {
      const img = document.createElement('img');
      img.src = image;
      img.alt = item.label || item.item_label || item.name || item.item_name;
      img.addEventListener('error', () => img.remove());
      wrap.appendChild(img);
    }

    const fallback = document.createElement('span');
    fallback.textContent = (item.label || item.item_label || item.name || item.item_name || '?').slice(0, 1).toUpperCase();
    wrap.appendChild(fallback);
    return wrap;
  }

  function badgeText(type, value) {
    if (type === 'category') {
      return (state.config.categoryLabels && state.config.categoryLabels[value]) || value || 'misc';
    }
    return (state.config.rarityLabels && state.config.rarityLabels[value]) || value || 'common';
  }

  function createBadges(item) {
    const badges = document.createElement('div');
    badges.className = 'badges';

    const category = document.createElement('span');
    category.className = 'badge category';
    category.textContent = badgeText('category', item.category);

    const rarity = document.createElement('span');
    rarity.className = `badge rarity-${item.rarity || 'common'}`;
    rarity.textContent = badgeText('rarity', item.rarity);

    badges.append(category, rarity);
    return badges;
  }

  function setLoading(isLoading) {
    state.pending = isLoading;
    elements.loader.classList.toggle('hidden', !isLoading);
    elements.loader.setAttribute('aria-hidden', String(!isLoading));
    elements.marketplace.classList.toggle('is-pending', isLoading);
    if (isLoading) renderSkeletons();
    renderSellPanel();
  }

  function renderSkeletons() {
    const target = state.activeTab === 'mine'
      ? elements.mineGrid
      : state.activeTab === 'offers'
        ? elements.offersGrid
        : state.activeTab === 'history'
          ? elements.historyList
          : elements.inventoryGrid;

    target.innerHTML = '';

    const count = state.activeTab === 'history' ? 4 : 6;
    for (let index = 0; index < count; index += 1) {
      const skeleton = document.createElement('div');
      skeleton.className = state.activeTab === 'history' ? 'skeleton-row' : 'skeleton-card';
      target.appendChild(skeleton);
    }
  }

  function toast(message, type = 'info') {
    const node = document.createElement('div');
    node.className = `toast ${type}`;
    node.textContent = message;
    elements.toastStack.appendChild(node);
    requestAnimationFrame(() => node.classList.add('visible'));
    setTimeout(() => {
      node.classList.remove('visible');
      setTimeout(() => node.remove(), 240);
    }, 3200);
  }

  function confirmAction(title, body) {
    return new Promise((resolve) => {
      setText(elements.confirmTitle, title);
      setText(elements.confirmBody, body);
      elements.modal.classList.remove('hidden');
      elements.modal.setAttribute('aria-hidden', 'false');

      const cleanup = (answer) => {
        elements.modal.classList.add('hidden');
        elements.modal.setAttribute('aria-hidden', 'true');
        elements.confirmCancel.removeEventListener('click', onCancel);
        elements.confirmAccept.removeEventListener('click', onAccept);
        resolve(answer);
      };

      const onCancel = () => cleanup(false);
      const onAccept = () => cleanup(true);
      elements.confirmCancel.addEventListener('click', onCancel);
      elements.confirmAccept.addEventListener('click', onAccept);
    });
  }

  async function nui(eventName, payload = {}) {
    if (DEMO) return demoResponse(eventName, payload);

    try {
      const response = await fetch(`https://${RESOURCE}/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
      });

      return await response.json();
    } catch (error) {
      return { success: false, message: t('toast.communication') };
    }
  }

  function applyLocale(locale) {
    state.locale = locale || 'fr';
    state.dict = window.NUI_LOCALES[state.locale] || window.NUI_LOCALES.en;
    document.documentElement.lang = state.locale;

    $$('[data-i18n]').forEach((node) => setText(node, t(node.dataset.i18n)));
    $$('[data-i18n-placeholder]').forEach((node) => {
      node.placeholder = t(node.dataset.i18nPlaceholder);
    });
  }

  function applyConfig(config = {}) {
    state.config = {
      locale: 'fr',
      title: 'QB Marketplace',
      subtitle: 'Community exchange',
      theme: 'purple',
      currency: '$',
      tax: { enabled: true, percentage: 5, round: 'floor' },
      expiration: { enabled: true, hours: 72 },
      limits: { price: { min: 1, max: 1000000 }, quantity: { min: 1, max: 250 } },
      categoryLabels: {},
      rarityLabels: {},
      ...config
    };

    applyLocale(state.config.locale);
    setText($('[data-i18n="app.title"]'), state.config.title || t('app.title'));
    setText($('[data-i18n="app.subtitle"]'), state.config.subtitle || t('app.subtitle'));
    setTheme(state.config.theme || 'purple');
    renderConfig();
  }

  function setTheme(theme) {
    elements.marketplace.dataset.theme = theme;
    $$('.theme-chip').forEach((button) => {
      button.classList.toggle('active', button.dataset.themeOption === theme);
    });
  }

  function mergeData(data = {}) {
    state.inventory = Array.isArray(data.inventory) ? data.inventory : [];
    state.offers = Array.isArray(data.offers) ? data.offers : [];
    state.myListings = Array.isArray(data.myListings) ? data.myListings : [];
    state.history = Array.isArray(data.history) ? data.history : [];

    setText(elements.statOffers, data.stats ? data.stats.offers || 0 : state.offers.length);
    setText(elements.statEarnings, money(data.stats ? data.stats.pendingEarnings || 0 : pendingEarnings()));
    rebuildCategoryFilters();
    renderAll();
  }

  function pendingEarnings() {
    return state.history.reduce((total, sale) => total + (!sale.withdrawn ? Number(sale.net_amount || 0) : 0), 0);
  }

  function rebuildCategoryFilters() {
    const categories = new Map();
    [...state.inventory, ...state.offers, ...state.myListings].forEach((item) => {
      const category = item.category || 'misc';
      categories.set(category, badgeText('category', category));
    });

    ['#inventory-category', '#offers-category'].forEach((selector) => {
      const select = $(selector);
      const current = select.value;
      select.innerHTML = '';

      const all = document.createElement('option');
      all.value = 'all';
      all.textContent = t('filters.allCategories');
      select.appendChild(all);

      Array.from(categories.entries())
        .sort((a, b) => a[1].localeCompare(b[1]))
        .forEach(([value, label]) => {
          const option = document.createElement('option');
          option.value = value;
          option.textContent = label;
          select.appendChild(option);
        });

      select.value = categories.has(current) ? current : 'all';
    });
  }

  function switchTab(tab) {
    state.activeTab = tab;
    $$('.tab').forEach((button) => button.classList.toggle('active', button.dataset.tab === tab));
    $$('.view').forEach((view) => view.classList.toggle('active', view.id === `view-${tab}`));
  }

  function inventoryMatches(item) {
    const search = state.filters.inventorySearch.trim().toLowerCase();
    const category = state.filters.inventoryCategory;
    const matchesSearch = !search || `${item.label} ${item.name}`.toLowerCase().includes(search);
    const matchesCategory = category === 'all' || item.category === category;
    return matchesSearch && matchesCategory;
  }

  function renderInventory() {
    elements.inventoryGrid.innerHTML = '';
    const items = state.inventory.filter(inventoryMatches);

    items.forEach((item) => {
      const card = document.createElement('button');
      card.type = 'button';
      card.className = 'item-card';
      card.classList.toggle('selected', state.selectedItem && state.selectedItem.name === item.name);

      const content = document.createElement('div');
      content.className = 'item-card-main';
      content.appendChild(createMedia(item));

      const text = document.createElement('div');
      const name = document.createElement('strong');
      name.textContent = item.label;
      const meta = document.createElement('span');
      meta.textContent = `${t('labels.stock')} ${item.amount}`;
      text.append(name, meta);
      content.appendChild(text);

      card.append(content, createBadges(item));
      card.addEventListener('click', () => {
        state.selectedItem = item;
        elements.sellQuantity.value = Math.min(Number(elements.sellQuantity.value || 1), item.amount);
        renderSellPanel();
        renderInventory();
      });

      elements.inventoryGrid.appendChild(card);
    });

    elements.inventoryEmpty.classList.toggle('hidden', items.length > 0);
  }

  function renderSellPanel() {
    const item = state.selectedItem;
    const quantity = Number(elements.sellQuantity.value || 0);
    const price = Number(elements.sellPrice.value || 0);
    const gross = Math.max(0, quantity * price);
    const tax = taxFor(gross);

    if (!item) {
      setText(elements.selectedLabel, t('sell.noSelection'));
      elements.selectedPreview.className = 'selected-preview muted-preview';
      elements.selectedPreview.innerHTML = '';
      const media = document.createElement('div');
      media.className = 'item-media placeholder';
      media.textContent = '?';
      const copy = document.createElement('div');
      const title = document.createElement('strong');
      title.textContent = t('sell.previewTitle');
      const body = document.createElement('span');
      body.textContent = t('sell.previewBody');
      copy.append(title, body);
      elements.selectedPreview.append(media, copy);
    } else {
      setText(elements.selectedLabel, `${item.amount} ${t('labels.stock').toLowerCase()}`);
      elements.selectedPreview.className = 'selected-preview';
      elements.selectedPreview.innerHTML = '';
      const copy = document.createElement('div');
      const title = document.createElement('strong');
      title.textContent = item.label;
      const body = document.createElement('span');
      body.textContent = `${badgeText('category', item.category)} · ${badgeText('rarity', item.rarity)}`;
      copy.append(title, body);
      elements.selectedPreview.append(createMedia(item), copy);
    }

    setText(elements.summaryGross, money(gross));
    setText(elements.summaryTax, money(tax));
    setText(elements.summaryNet, money(gross - tax));

    const valid = Boolean(item) && quantity > 0 && price > 0 && item && quantity <= item.amount;
    elements.createButton.disabled = !valid || state.pending;
  }

  function offerMatches(item) {
    const search = state.filters.offersSearch.trim().toLowerCase();
    const category = state.filters.offersCategory;
    const matchesSearch = !search || `${item.item_label} ${item.item_name} ${item.seller || ''}`.toLowerCase().includes(search);
    const matchesCategory = category === 'all' || item.category === category;
    return matchesSearch && matchesCategory;
  }

  function sortOffers(items) {
    return [...items].sort((a, b) => {
      if (state.filters.offersSort === 'price-asc') return Number(a.price) - Number(b.price);
      if (state.filters.offersSort === 'price-desc') return Number(b.price) - Number(a.price);

      const ad = new Date(String(a.created_at || 0).replace(' ', 'T')).getTime() || 0;
      const bd = new Date(String(b.created_at || 0).replace(' ', 'T')).getTime() || 0;
      return state.filters.offersSort === 'date-asc' ? ad - bd : bd - ad;
    });
  }

  function renderOfferCard(item, mode) {
    const card = document.createElement('article');
    card.className = `offer-card ${item.status === 'expired' ? 'expired' : ''}`;

    const head = document.createElement('div');
    head.className = 'offer-head';
    head.appendChild(createMedia({
      name: item.item_name,
      label: item.item_label,
      image: item.item_image
    }));

    const title = document.createElement('div');
    const name = document.createElement('strong');
    name.textContent = item.item_label || item.item_name;
    const meta = document.createElement('span');
    meta.textContent = `${money(item.price)} / ${t('labels.unit')}`;
    title.append(name, meta);
    head.appendChild(title);
    card.appendChild(head);

    card.appendChild(createBadges(item));

    const facts = document.createElement('div');
    facts.className = 'facts';
    const stock = document.createElement('span');
    stock.textContent = `${t('labels.stock')}: ${item.quantity}`;
    const expires = document.createElement('span');
    expires.textContent = `${t('labels.expires')}: ${dateLabel(item.expires_at)}`;
    facts.append(stock, expires);
    if (item.seller) {
      const seller = document.createElement('span');
      seller.textContent = `${t('labels.seller')}: ${item.seller}`;
      facts.appendChild(seller);
    }
    card.appendChild(facts);

    const actions = document.createElement('div');
    actions.className = 'card-actions';

    if (mode === 'buy') {
      const quantity = document.createElement('input');
      quantity.type = 'number';
      quantity.min = '1';
      quantity.max = String(item.quantity);
      quantity.value = '1';
      quantity.className = 'mini-input';

      const buy = document.createElement('button');
      buy.type = 'button';
      buy.className = 'primary-button compact';
      buy.textContent = t('actions.buy');
      buy.addEventListener('click', () => buyListing(item, Number(quantity.value || 1)));

      actions.append(quantity, buy);
    } else {
      const status = document.createElement('span');
      status.className = `status-pill ${item.status || 'active'}`;
      status.textContent = t(`status.${item.status || 'active'}`);

      const cancel = document.createElement('button');
      cancel.type = 'button';
      cancel.className = 'secondary-button compact';
      cancel.textContent = t('actions.cancelListing');
      cancel.addEventListener('click', () => cancelListing(item));

      actions.append(status, cancel);
    }

    card.appendChild(actions);
    return card;
  }

  function renderOffers() {
    elements.offersGrid.innerHTML = '';
    const offers = sortOffers(state.offers.filter(offerMatches));
    offers.forEach((item) => elements.offersGrid.appendChild(renderOfferCard(item, 'buy')));
    elements.offersEmpty.classList.toggle('hidden', offers.length > 0);
  }

  function renderMine() {
    elements.mineGrid.innerHTML = '';
    const status = state.filters.mineStatus;
    const items = state.myListings.filter((item) => status === 'all' || item.status === status);
    items.forEach((item) => elements.mineGrid.appendChild(renderOfferCard(item, 'mine')));
    elements.mineEmpty.classList.toggle('hidden', items.length > 0);
  }

  function renderHistory() {
    elements.historyList.innerHTML = '';

    state.history.forEach((sale) => {
      const row = document.createElement('label');
      row.className = `history-row ${sale.withdrawn ? 'is-withdrawn' : ''}`;

      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.disabled = Boolean(sale.withdrawn);
      checkbox.checked = state.selectedHistory.has(Number(sale.id));
      checkbox.addEventListener('change', () => {
        const id = Number(sale.id);
        if (checkbox.checked) state.selectedHistory.add(id);
        else state.selectedHistory.delete(id);
      });

      const main = document.createElement('div');
      main.className = 'history-main';
      const title = document.createElement('strong');
      title.textContent = `${sale.quantity}x ${sale.item_label || sale.item_name}`;
      const meta = document.createElement('span');
      meta.textContent = `${t('labels.buyer')}: ${sale.buyer_name || '-'} · ${dateLabel(sale.created_at)}`;
      main.append(title, meta);

      const amounts = document.createElement('div');
      amounts.className = 'history-amounts';
      const gross = document.createElement('span');
      gross.textContent = `${t('labels.total')}: ${money(sale.gross_amount)}`;
      const net = document.createElement('strong');
      net.textContent = `${t('labels.net')}: ${money(sale.net_amount)}`;
      const status = document.createElement('small');
      status.textContent = sale.withdrawn ? t('status.withdrawn') : t('status.pending');
      amounts.append(gross, net, status);

      row.append(checkbox, main, amounts);
      elements.historyList.appendChild(row);
    });

    elements.historyEmpty.classList.toggle('hidden', state.history.length > 0);
  }

  function renderConfig() {
    const config = state.config;
    const rows = [
      [t('settings.locale'), config.locale],
      [t('settings.currency'), config.currency],
      [t('settings.tax'), config.tax && config.tax.enabled ? `${config.tax.percentage}%` : '0%'],
      [t('settings.expiration'), config.expiration && config.expiration.enabled ? `${config.expiration.hours}h` : t('time.noExpiration')],
      [t('settings.buyerAccount'), config.accounts && config.accounts.buyerPayment],
      [t('settings.sellerAccount'), config.accounts && config.accounts.sellerPayout]
    ];

    elements.configList.innerHTML = '';
    rows.forEach(([label, value]) => {
      const dt = document.createElement('dt');
      dt.textContent = label;
      const dd = document.createElement('dd');
      dd.textContent = value || '-';
      elements.configList.append(dt, dd);
    });
  }

  function renderAll() {
    renderInventory();
    renderSellPanel();
    renderOffers();
    renderMine();
    renderHistory();
    renderConfig();
  }

  async function refresh() {
    setLoading(true);
    try {
      const result = await nui('refresh');
      if (result.success) mergeData(result.data);
      else toast(result.message || 'Refresh failed', 'error');
    } finally {
      setLoading(false);
    }
  }

  async function createListing() {
    const item = state.selectedItem;
    const quantity = Number(elements.sellQuantity.value || 0);
    const price = Number(elements.sellPrice.value || 0);

    if (!item || quantity < 1 || price < 1) {
      toast(t('toast.invalidSelection'), 'error');
      return;
    }

    if (quantity > item.amount) {
      toast(t('toast.quantityTooHigh'), 'error');
      return;
    }

    const accepted = await confirmAction(t('confirm.publishTitle'), t('confirm.publishBody'));
    if (!accepted) return;

    setLoading(true);
    try {
      const result = await nui('createListing', { itemName: item.name, quantity, price });
      if (result.success) {
        state.selectedItem = null;
        toast(result.message, 'success');
        mergeData(result.data);
      } else {
        toast(result.message || 'Unable to publish listing', 'error');
      }
    } finally {
      setLoading(false);
    }
  }

  async function buyListing(item, quantity) {
    if (!quantity || quantity < 1 || quantity > Number(item.quantity)) {
      toast(t('toast.invalidSelection'), 'error');
      return;
    }

    const total = money(Number(item.price) * quantity);
    const accepted = await confirmAction(t('confirm.buyTitle'), `${t('confirm.buyBody')} ${total}`);
    if (!accepted) return;

    setLoading(true);
    try {
      const result = await nui('buyListing', { listingId: item.id, quantity });
      if (result.success) {
        toast(result.message, 'success');
        mergeData(result.data);
      } else {
        toast(result.message || 'Purchase failed', 'error');
      }
    } finally {
      setLoading(false);
    }
  }

  async function cancelListing(item) {
    const accepted = await confirmAction(t('confirm.cancelTitle'), t('confirm.cancelBody'));
    if (!accepted) return;

    setLoading(true);
    try {
      const result = await nui('cancelListing', { listingId: item.id });
      if (result.success) {
        toast(result.message, 'success');
        mergeData(result.data);
      } else {
        toast(result.message || 'Cancel failed', 'error');
      }
    } finally {
      setLoading(false);
    }
  }

  async function withdrawSelected() {
    const ids = Array.from(state.selectedHistory);
    if (ids.length === 0) {
      toast(t('toast.selectEarnings'), 'error');
      return;
    }

    setLoading(true);
    try {
      const result = await nui('withdrawEarnings', { ids });
      if (result.success) {
        state.selectedHistory.clear();
        toast(result.message, 'success');
        mergeData(result.data);
      } else {
        toast(result.message || 'Withdraw failed', 'error');
      }
    } finally {
      setLoading(false);
    }
  }

  function open(config, data) {
    applyConfig(config);
    mergeData(data);
    elements.app.classList.add('is-open');
    elements.app.setAttribute('aria-hidden', 'false');
    switchTab('sell');
  }

  function close() {
    elements.app.classList.remove('is-open');
    elements.app.setAttribute('aria-hidden', 'true');
  }

  function bindEvents() {
    $('#close-btn').addEventListener('click', async () => {
      await nui('close');
      close();
    });
    $('#refresh-btn').addEventListener('click', refresh);
    elements.createButton.addEventListener('click', createListing);
    $('#withdraw-btn').addEventListener('click', withdrawSelected);

    $$('.tab').forEach((button) => {
      button.addEventListener('click', () => switchTab(button.dataset.tab));
    });

    $('#inventory-search').addEventListener('input', (event) => {
      state.filters.inventorySearch = event.target.value;
      renderInventory();
    });
    $('#inventory-category').addEventListener('change', (event) => {
      state.filters.inventoryCategory = event.target.value;
      renderInventory();
    });
    $('#offers-search').addEventListener('input', (event) => {
      state.filters.offersSearch = event.target.value;
      renderOffers();
    });
    $('#offers-category').addEventListener('change', (event) => {
      state.filters.offersCategory = event.target.value;
      renderOffers();
    });
    $('#offers-sort').addEventListener('change', (event) => {
      state.filters.offersSort = event.target.value;
      renderOffers();
    });
    $('#mine-filter').addEventListener('change', (event) => {
      state.filters.mineStatus = event.target.value;
      renderMine();
    });

    [elements.sellQuantity, elements.sellPrice].forEach((input) => {
      input.addEventListener('input', renderSellPanel);
    });

    $$('.theme-chip').forEach((button) => {
      button.addEventListener('click', () => setTheme(button.dataset.themeOption));
    });

    document.addEventListener('keydown', async (event) => {
      if (event.key === 'Escape' && elements.app.classList.contains('is-open')) {
        await nui('close');
        close();
      }
    });
  }

  window.addEventListener('message', (event) => {
    const payload = event.data || {};
    if (payload.action === 'open') open(payload.config, payload.data);
    if (payload.action === 'close') close();
    if (payload.action === 'toast') toast(payload.message, payload.toastType);
  });

  function demoResponse(eventName, payload) {
    if (eventName === 'close') return Promise.resolve({ success: true });

    if (eventName === 'createListing') {
      return Promise.resolve({
        success: true,
        message: 'Offre publiee avec succes.',
        data: demoData()
      });
    }

    if (eventName === 'buyListing') {
      return Promise.resolve({ success: true, message: 'Achat effectue avec succes.', data: demoData() });
    }

    if (eventName === 'cancelListing') {
      return Promise.resolve({ success: true, message: 'Offre annulee et objet rendu.', data: demoData() });
    }

    if (eventName === 'withdrawEarnings') {
      const data = demoData();
      data.history = data.history.map((sale) => ({ ...sale, withdrawn: true }));
      data.stats.pendingEarnings = 0;
      return Promise.resolve({ success: true, message: 'Gains retires : $4,750.', data });
    }

    return Promise.resolve({ success: true, data: demoData() });
  }

  function demoData() {
    return {
      inventory: [
        { name: 'lockpick', label: 'Lockpick', amount: 12, rarity: 'common', category: 'tools', image: '' },
        { name: 'advancedlockpick', label: 'Advanced Lockpick', amount: 4, rarity: 'rare', category: 'tools', image: '' },
        { name: 'radio', label: 'Radio', amount: 2, rarity: 'uncommon', category: 'electronics', image: '' },
        { name: 'weapon_pistol', label: 'Pistol', amount: 1, rarity: 'epic', category: 'weapons', image: '' }
      ],
      offers: [
        { id: 1, item_name: 'advancedlockpick', item_label: 'Advanced Lockpick', quantity: 8, price: 650, seller: 'Nora Blake', rarity: 'rare', category: 'tools', created_at: '2026-06-14 18:25:00', expires_at: '2026-06-17 18:25:00' },
        { id: 2, item_name: 'radio', item_label: 'Radio', quantity: 3, price: 1200, seller: 'Ilyes Ward', rarity: 'uncommon', category: 'electronics', created_at: '2026-06-14 16:10:00', expires_at: '2026-06-17 16:10:00' },
        { id: 3, item_name: 'weapon_pistol', item_label: 'Pistol', quantity: 1, price: 8500, seller: 'Maya Stone', rarity: 'epic', category: 'weapons', created_at: '2026-06-13 21:40:00', expires_at: '2026-06-16 21:40:00' }
      ],
      myListings: [
        { id: 11, item_name: 'lockpick', item_label: 'Lockpick', quantity: 5, price: 220, rarity: 'common', category: 'tools', status: 'active', created_at: '2026-06-14 17:15:00', expires_at: '2026-06-17 17:15:00' },
        { id: 12, item_name: 'radio', item_label: 'Radio', quantity: 1, price: 1400, rarity: 'uncommon', category: 'electronics', status: 'expired', created_at: '2026-06-10 12:00:00', expires_at: '2026-06-13 12:00:00' }
      ],
      history: [
        { id: 100, listing_id: 11, item_name: 'lockpick', item_label: 'Lockpick', quantity: 10, unit_price: 250, gross_amount: 2500, tax_amount: 125, net_amount: 2375, buyer_name: 'Sam Rivers', withdrawn: false, created_at: '2026-06-14 14:45:00' },
        { id: 101, listing_id: 12, item_name: 'radio', item_label: 'Radio', quantity: 2, unit_price: 1250, gross_amount: 2500, tax_amount: 125, net_amount: 2375, buyer_name: 'Jo Carter', withdrawn: false, created_at: '2026-06-13 20:10:00' }
      ],
      stats: { offers: 3, myListings: 2, pendingEarnings: 4750, taxPercent: 5 }
    };
  }

  bindEvents();

  if (DEMO) {
    document.body.classList.add('demo-preview');
    open({
      locale: 'fr',
      title: 'QB Marketplace',
      subtitle: 'Marketplace FiveM/QBCore',
      theme: 'purple',
      currency: '$',
      showSeller: true,
      tax: { enabled: true, percentage: 5, round: 'floor' },
      expiration: { enabled: true, hours: 72 },
      limits: { price: { min: 1, max: 1000000 }, quantity: { min: 1, max: 250 } },
      categoryLabels: { misc: 'Divers', tools: 'Outils', weapons: 'Armes', electronics: 'Électronique' },
      rarityLabels: { common: 'Commun', uncommon: 'Peu commun', rare: 'Rare', epic: 'Épique', legendary: 'Légendaire' },
      accounts: { buyerPayment: 'bank', sellerPayout: 'bank' }
    }, demoData());
  }
})();
