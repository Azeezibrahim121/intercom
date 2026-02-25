<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>BountyBoard — Trac Network</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Space+Mono:ital,wght@0,400;0,700;1,400&family=Syne:wght@400;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #050810;
      --bg2: #0b1020;
      --bg3: #111827;
      --border: #1e2d4d;
      --accent: #00e5ff;
      --accent2: #ff4d6d;
      --accent3: #7fffb2;
      --gold: #ffd166;
      --text: #c8d8f0;
      --dim: #4a6080;
      --font-mono: 'Space Mono', monospace;
      --font-display: 'Syne', sans-serif;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      background: var(--bg);
      color: var(--text);
      font-family: var(--font-mono);
      min-height: 100vh;
      overflow-x: hidden;
    }

    body::before {
      content: '';
      position: fixed;
      inset: 0;
      background: repeating-linear-gradient(
        0deg,
        transparent,
        transparent 2px,
        rgba(0,229,255,0.015) 2px,
        rgba(0,229,255,0.015) 4px
      );
      pointer-events: none;
      z-index: 999;
    }

    body::after {
      content: '';
      position: fixed;
      inset: 0;
      background-image:
        linear-gradient(rgba(0,229,255,0.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(0,229,255,0.03) 1px, transparent 1px);
      background-size: 40px 40px;
      pointer-events: none;
      z-index: 0;
    }

    .app {
      position: relative;
      z-index: 1;
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 24px 80px;
    }

    header {
      padding: 32px 0 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 1px solid var(--border);
      margin-bottom: 32px;
    }

    .logo-group { display: flex; align-items: center; gap: 16px; }

    .logo-icon {
      width: 44px; height: 44px;
      background: var(--accent);
      clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%);
      display: flex; align-items: center; justify-content: center;
      font-size: 20px;
      box-shadow: 0 0 20px rgba(0,229,255,0.4);
      animation: pulse-glow 3s ease-in-out infinite;
    }

    @keyframes pulse-glow {
      0%, 100% { box-shadow: 0 0 20px rgba(0,229,255,0.4); }
      50% { box-shadow: 0 0 40px rgba(0,229,255,0.7), 0 0 80px rgba(0,229,255,0.2); }
    }

    .logo-text h1 {
      font-family: var(--font-display);
      font-size: 22px;
      font-weight: 800;
      color: #fff;
      letter-spacing: -0.5px;
    }

    .logo-text p {
      font-size: 10px;
      color: var(--dim);
      text-transform: uppercase;
      letter-spacing: 2px;
    }

    .header-stats { display: flex; gap: 24px; }

    .stat-chip { text-align: right; }

    .stat-chip .val {
      font-family: var(--font-display);
      font-size: 20px;
      font-weight: 700;
      color: var(--accent);
    }

    .stat-chip .lbl {
      font-size: 10px;
      color: var(--dim);
      text-transform: uppercase;
      letter-spacing: 1.5px;
    }
  </style>
  </head>
<body>
<div class="app">

  <header>
    <div class="logo-group">
      <div class="logo-icon">🎯</div>
      <div class="logo-text">
        <h1>BountyBoard</h1>
        <p>Trac Network · P2P · Decentralized</p>
      </div>
    </div>
    <div class="header-stats">
      <div class="stat-chip">
        <div class="val" id="stat-open">--</div>
        <div class="lbl">Open</div>
      </div>
      <div class="stat-chip">
        <div class="val" id="stat-total">--</div>
        <div class="lbl">Total</div>
      </div>
      <div class="stat-chip">
        <div class="val" id="stat-pool">--</div>
        <div class="lbl">Pool TAP</div>
      </div>
    </div>
  </header>

  <div class="identity-bar">
    <div>
      <span class="label">Your Address:</span>
      <span class="addr" id="my-addr">Loading...</span>
    </div>
    <div>
      <span class="label">Network Status:</span>
      <span id="net-status" style="color:var(--dim)">Connecting...</span>
    </div>
  </div>

  <div class="tabs">
    <button class="tab active" data-tab="board">📋 Board</button>
    <button class="tab" data-tab="post">➕ Post Bounty</button>
    <button class="tab" data-tab="my-bounties">👤 My Bounties</button>
    <button class="tab" data-tab="leaderboard">🏆 Leaderboard</button>
  </div>

  <div id="tab-board" class="tab-pane">
    <div class="filter-bar">
      <button class="filter-btn active" data-filter="all">All</button>
      <button class="filter-btn" data-filter="open">Open</button>
      <button class="filter-btn" data-filter="claimed">Claimed</button>
      <button class="filter-btn" data-filter="completed">Completed</button>
      <input type="text" class="search-box" placeholder="Search bounties..." id="search-input">
    </div>
    <div class="bounty-grid" id="bounty-grid">
      <div class="loading"><div class="spinner"></div><br>Loading bounties...</div>
    </div>
  </div>

  <div id="tab-post" class="tab-pane" style="display:none">
    <form class="post-form" id="post-form">
      <div class="form-title">Post a New Bounty</div>
      <div class="form-row">
        <label>Title *</label>
        <input type="text" id="f-title" maxlength="120" placeholder="e.g. Fix critical bug in payment module" required>
      </div>
      <div class="form-row">
        <label>Description *</label>
        <textarea id="f-desc" rows="5" maxlength="1000" placeholder="Describe the task clearly..." required></textarea>
      </div>
      <div class="form-row">
        <label>Reward Amount *</label>
        <input type="number" id="f-reward" min="1" placeholder="100" required>
      </div>
      <div class="form-row">
        <label>Token *</label>
        <select id="f-token">
          <option value="TAP">TAP</option>
          <option value="TRAC">TRAC</option>
        </select>
      </div>
      <div class="form-row">
        <label>Tags (comma-separated)</label>
        <input type="text" id="f-tags" placeholder="dev, frontend, bug, design">
      </div>
      <div class="card-actions">
        <button type="submit" class="btn btn-primary" id="post-submit-btn">⚡ Post Bounty</button>
        <button type="button" class="btn btn-ghost" id="post-reset-btn">Clear</button>
      </div>
    </form>
  </div>

  <div id="tab-my-bounties" class="tab-pane" style="display:none">
    <div class="bounty-grid" id="my-bounty-grid">
      <div class="loading"><div class="spinner"></div><br>Loading...</div>
    </div>
  </div>

  <div id="tab-leaderboard" class="tab-pane" style="display:none">
    <div class="leaderboard-table">
      <div class="lb-header">
        <div>#</div>
        <div>Address</div>
        <div>Posted</div>
        <div>Completed</div>
        <div>Earned (TAP)</div>
      </div>
      <div id="lb-body"></div>
    </div>
  </div>

</div>

<div class="modal-overlay" id="modal" style="display:none">
  <div class="modal">
    <h2 id="modal-title">Confirm</h2>
    <p id="modal-body">Are you sure?</p>
    <div class="modal-actions">
      <button class="btn btn-ghost" id="modal-cancel">Cancel</button>
      <button class="btn btn-primary" id="modal-confirm">Confirm</button>
    </div>
  </div>
</div>

<div class="toast-container" id="toasts"></div>
<script>
let myAddress = null
const MOCK_BOUNTIES = []

function fmtAddr(addr) {
  if (!addr) return '???'
  if (addr.length <= 16) return addr
  return addr.slice(0, 8) + '...' + addr.slice(-6)
}

function fmtTime(ts) {
  if (!ts) return ''
  const diff = Date.now() - ts
  if (diff < 60000) return 'just now'
  if (diff < 3600000) return Math.floor(diff / 60000) + 'm ago'
  if (diff < 86400000) return Math.floor(diff / 3600000) + 'h ago'
  return Math.floor(diff / 86400000) + 'd ago'
}

function toast(msg, type = 'info') {
  const el = document.createElement('div')
  el.className = `toast ${type}`
  el.textContent = msg
  document.getElementById('toasts').appendChild(el)
  setTimeout(() => el.remove(), 4000)
}

function useMockData() {
  const now = Date.now()
  MOCK_BOUNTIES.push(
    { id: 'b001', title: 'Build a P2P chat UI for BountyBoard', description: 'We need a real-time chat panel embedded inside the bounty card so claimant and poster can communicate directly via the Intercom sidechannel.', reward: 500, reward_token: 'TAP', poster: 'peer_abc123', claimant: null, status: 'open', tags: ['dev', 'ui', 'p2p'], created_at: now - 86400000 },
    { id: 'b002', title: 'Write comprehensive test suite for contract', description: 'Cover all edge cases for post_bounty, claim_bounty, complete_bounty and cancel_bounty. Must achieve 100% branch coverage.', reward: 300, reward_token: 'TAP', poster: 'peer_xyz789', claimant: myAddress, status: 'claimed', tags: ['testing', 'js'], created_at: now - 172800000 },
    { id: 'b003', title: 'Design app logo and brand kit', description: 'Create a logo, color palette, and icon set for BountyBoard. Deliverables: SVG logo, 5 UI icons, brand guide doc.', reward: 250, reward_token: 'TAP', poster: 'peer_def456', claimant: 'peer_ghi012', status: 'completed', tags: ['design'], created_at: now - 345600000 },
    { id: 'b004', title: 'Integrate Hyperswarm DHT auto-discovery', description: 'Improve peer discovery by integrating Hyperswarm DHT so new peers can find the network without needing the bootstrap key manually.', reward: 750, reward_token: 'TAP', poster: myAddress, claimant: null, status: 'open', tags: ['networking', 'p2p'], created_at: now - 3600000 },
    { id: 'b005', title: 'Write onboarding docs', description: 'Create beginner-friendly docs for setting up BountyBoard locally. Should include screenshots, common errors, and FAQ.', reward: 100, reward_token: 'TAP', poster: 'peer_jkl345', claimant: null, status: 'open', tags: ['docs'], created_at: now - 7200000 }
  )
}

async function apiQuery(method, params = {}) {
  let list = [...MOCK_BOUNTIES]
  if (method === 'get_bounties') {
    if (params.status) list = list.filter(b => b.status === params.status)
    if (params.poster) list = list.filter(b => b.poster === params.poster)
    list.sort((a, b) => b.created_at - a.created_at)
    return list
  }
  if (method === 'get_leaderboard') {
    return [
      { address: 'peer_ghi012', posted: 2, completed: 5, earned: 1200 },
      { address: myAddress, posted: 3, completed: 2, earned: 650 },
      { address: 'peer_abc123', posted: 1, completed: 3, earned: 450 },
    ]
  }
  return []
}

async function apiTx(func, data) {
  if (func === 'post_bounty') {
    const id = 'b' + Date.now()
    MOCK_BOUNTIES.unshift({ id, ...data, reward_token: data.reward_token || 'TAP', tags: data.tags || [], poster: myAddress, claimant: null, status: 'open', created_at: Date.now() })
    return { success: true, id }
  }
  if (func === 'claim_bounty') {
    const b = MOCK_BOUNTIES.find(x => x.id === data.id)
    if (!b) return { error: 'Not found' }
    b.status = 'claimed'; b.claimant = myAddress; b.claimed_at = Date.now()
    return { success: true }
  }
  if (func === 'complete_bounty') {
    const b = MOCK_BOUNTIES.find(x => x.id === data.id)
    if (!b) return { error: 'Not found' }
    b.status = 'completed'; b.completed_at = Date.now()
    return { success: true }
  }
  if (func === 'cancel_bounty') {
    const b = MOCK_BOUNTIES.find(x => x.id === data.id)
    if (!b) return { error: 'Not found' }
    b.status = 'cancelled'
    return { success: true }
  }
  return { error: 'Unknown' }
}

function escHtml(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
}

function renderCard(b) {
  const canClaim = b.status === 'open' && b.poster !== myAddress
  const canComplete = b.status === 'claimed' && b.poster === myAddress
  const canCancel = b.status === 'open' && b.poster === myAddress
  const isMyBounty = b.poster === myAddress
  const tagHtml = b.tags && b.tags.length ? `<div class="card-tags">${b.tags.map(t => `<span class="tag">#${t}</span>`).join('')}</div>` : ''
  const actionsBtns = []
  if (canClaim) actionsBtns.push(`<button class="btn btn-primary" onclick="doClaim('${b.id}')">⚡ Claim</button>`)
  if (canComplete) actionsBtns.push(`<button class="btn btn-success" onclick="doComplete('${b.id}')">✅ Mark Complete</button>`)
  if (canCancel) actionsBtns.push(`<button class="btn btn-danger" onclick="doCancel('${b.id}')">✕ Cancel</button>`)
  return `
    <div class="bounty-card status-${b.status}">
      <div class="card-header">
        <div class="card-title">${escHtml(b.title)}</div>
        <div class="status-badge status-${b.status}">${b.status}</div>
      </div>
      <div class="card-desc">${escHtml(b.description)}</div>
      ${tagHtml}
      <div class="card-meta">
        <div class="reward">${Number(b.reward).toLocaleString()}<span class="token">${b.reward_token}</span></div>
      </div>
      <div class="card-footer">
        <div class="poster-addr">by <span>${fmtAddr(b.poster)}${isMyBounty ? ' (you)' : ''}</span></div>
        <div class="card-time">${fmtTime(b.created_at)}</div>
      </div>
      ${actionsBtns.length ? `<div class="card-actions">${actionsBtns.join('')}</div>` : ''}
    </div>`
}

async function loadBoard() {
  const grid = document.getElementById('bounty-grid')
  let bounties = await apiQuery('get_bounties')
  const open = bounties.filter(b => b.status === 'open')
  document.getElementById('stat-open').textContent = open.length
  document.getElementById('stat-total').textContent = bounties.length
  document.getElementById('stat-pool').textContent = open.reduce((s, b) => s + (b.reward_token === 'TAP' ? b.reward : 0), 0).toLocaleString()
  if (!bounties.length) { grid.innerHTML = `<div class="empty" style="grid-column:1/-1"><h3>No bounties yet!</h3></div>`; return }
  grid.innerHTML = bounties.map(b => renderCard(b)).join('')
}

async function loadMyBounties() {
  const grid = document.getElementById('my-bounty-grid')
  let bounties = await apiQuery('get_bounties')
  bounties = bounties.filter(b => b.poster === myAddress || b.claimant === myAddress)
  if (!bounties.length) { grid.innerHTML = `<div class="empty" style="grid-column:1/-1"><h3>Nothing here yet</h3></div>`; return }
  grid.innerHTML = bounties.map(b => renderCard(b)).join('')
}

async function loadLeaderboard() {
  const body = document.getElementById('lb-body')
  const data = await apiQuery('get_leaderboard')
  body.innerHTML = data.map((row, i) => `
    <div class="lb-row">
      <div class="lb-rank">${i + 1}</div>
      <div class="lb-addr">${fmtAddr(row.address)}</div>
      <div>${row.posted}</div>
      <div>${row.completed}</div>
      <div class="lb-earned">${Number(row.earned).toLocaleString()}</div>
    </div>`).join('')
}

async function doClaim(id) {
  const r = await apiTx('claim_bounty', { id })
  if (r.error) { toast('Error: ' + r.error, 'error'); return }
  toast('Bounty claimed! 🚀', 'success')
  loadBoard()
}

async function doComplete(id) {
  const r = await apiTx('complete_bounty', { id })
  if (r.error) { toast('Error: ' + r.error, 'error'); return }
  toast('Bounty completed! ✅', 'success')
  loadBoard()
}

async function doCancel(id) {
  const r = await apiTx('cancel_bounty', { id })
  if (r.error) { toast('Error: ' + r.error, 'error'); return }
  toast('Bounty cancelled', 'info')
  loadBoard()
}

document.getElementById('post-form').addEventListener('submit', async e => {
  e.preventDefault()
  const title = document.getElementById('f-title').value.trim()
  const description = document.getElementById('f-desc').value.trim()
  const reward = parseFloat(document.getElementById('f-reward').value)
  const reward_token = document.getElementById('f-token').value
  const tagsRaw = document.getElementById('f-tags').value
  const tags = tagsRaw ? tagsRaw.split(',').map(t => t.trim()).filter(Boolean) : []
  const btn = document.getElementById('post-submit-btn')
  btn.disabled = true; btn.textContent = '⏳ Posting...'
  const r = await apiTx('post_bounty', { title, description, reward, reward_token, tags })
  btn.disabled = false; btn.textContent = '⚡ Post Bounty'
  if (r.error) { toast('Error: ' + r.error, 'error'); return }
  toast('Bounty posted! 🎯', 'success')
  document.getElementById('post-form').reset()
  switchTab('board')
  loadBoard()
})

document.getElementById('post-reset-btn').addEventListener('click', () => {
  document.getElementById('post-form').reset()
})

function switchTab(name) {
  document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === name))
  document.querySelectorAll('.tab-pane').forEach(p => p.style.display = 'none')
  document.getElementById('tab-' + name).style.display = 'block'
  if (name === 'board') loadBoard()
  if (name === 'my-bounties') loadMyBounties()
  if (name === 'leaderboard') loadLeaderboard()
}

document.querySelectorAll('.tab').forEach(t => {
  t.addEventListener('click', () => switchTab(t.dataset.tab))
})

myAddress = 'demo_' + Math.random().toString(36).slice(2, 10)
document.getElementById('my-addr').textContent = fmtAddr(myAddress)
document.getElementById('net-status').textContent = '🟡 Demo Mode'
document.getElementById('net-status').style.color = 'var(--gold)'
useMockData()
loadBoard()
</script>
</body>
</html>
