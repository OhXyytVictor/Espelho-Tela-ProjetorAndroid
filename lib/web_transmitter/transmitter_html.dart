// Embedded HTML/JS/CSS client for mobile devices (Android & iOS)
// Served directly by the local HTTP server on the projector.
// No external internet or CDNs needed - 100% offline & local.

const String mobileTransmitterHtml = '''<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>LumiCast - Transmitir Tela</title>
  <style>
    :root {
      --bg: #0c0f17;
      --card: #161c28;
      --accent: #3b82f6;
      --accent-glow: rgba(59, 130, 246, 0.4);
      --green: #10b981;
      --text: #f3f4f6;
      --subtext: #9ca3af;
      --danger: #ef4444;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      -webkit-tap-highlight-color: transparent;
    }
    body {
      background: var(--bg);
      color: var(--text);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
      text-align: center;
    }
    .container {
      width: 100%;
      max-width: 420px;
      background: var(--card);
      border-radius: 24px;
      padding: 32px 24px;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5);
      border: 1px solid rgba(255, 255, 255, 0.08);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(59, 130, 246, 0.15);
      color: var(--accent);
      padding: 6px 14px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 20px;
    }
    .badge.active {
      background: rgba(16, 185, 129, 0.15);
      color: var(--green);
    }
    .badge-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: currentColor;
    }
    h1 {
      font-size: 26px;
      font-weight: 700;
      margin-bottom: 8px;
      letter-spacing: -0.5px;
    }
    p.desc {
      color: var(--subtext);
      font-size: 15px;
      line-height: 1.5;
      margin-bottom: 28px;
    }
    .btn {
      width: 100%;
      padding: 18px 24px;
      font-size: 17px;
      font-weight: 600;
      border-radius: 16px;
      border: none;
      cursor: pointer;
      transition: all 0.2s ease;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
    }
    .btn-primary {
      background: var(--accent);
      color: white;
      box-shadow: 0 4px 20px var(--accent-glow);
    }
    .btn-primary:active {
      transform: scale(0.98);
      filter: brightness(0.9);
    }
    .btn-danger {
      background: rgba(239, 68, 68, 0.15);
      color: var(--danger);
      border: 1px solid rgba(239, 68, 68, 0.3);
      margin-top: 12px;
    }
    .btn-danger:active {
      transform: scale(0.98);
    }
    .options-box {
      margin-top: 24px;
      padding-top: 20px;
      border-top: 1px solid rgba(255, 255, 255, 0.08);
      display: flex;
      flex-direction: column;
      gap: 12px;
      text-align: left;
    }
    .opt-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 14px;
      color: var(--subtext);
    }
    .opt-row span.label {
      color: var(--text);
      font-weight: 500;
    }
    select {
      background: rgba(255, 255, 255, 0.06);
      color: var(--text);
      border: 1px solid rgba(255, 255, 255, 0.15);
      padding: 6px 10px;
      border-radius: 8px;
      font-size: 13px;
      outline: none;
    }
    .status-msg {
      margin-top: 18px;
      font-size: 13px;
      color: var(--subtext);
      min-height: 20px;
    }
    .preview-container {
      margin-top: 16px;
      display: none;
      border-radius: 12px;
      overflow: hidden;
      border: 1px solid rgba(255, 255, 255, 0.1);
    }
    video#preview {
      width: 100%;
      height: auto;
      max-height: 180px;
      background: black;
      display: block;
    }
    footer {
      margin-top: 24px;
      font-size: 12px;
      color: rgba(255, 255, 255, 0.3);
    }
  </style>
</head>
<body>
  <div class="container">
    <div id="badgeStatus" class="badge">
      <div class="badge-dot"></div>
      <span id="badgeText">Pronto para conectar</span>
    </div>

    <h1>LumiCast</h1>
    <p class="desc">Espelhamento direto no seu projetor T15 PRO. Sem anúncios, sem assinaturas.</p>

    <button id="btnStart" class="btn btn-primary" onclick="startMirroring()">
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect>
        <line x1="8" y1="21" x2="16" y2="21"></line>
        <line x1="12" y1="17" x2="12" y2="21"></line>
      </svg>
      Iniciar Espelhamento
    </button>

    <button id="btnStop" class="btn btn-danger" style="display: none;" onclick="stopMirroring()">
      Parar Transmissão
    </button>

    <div class="options-box">
      <div class="opt-row">
        <span class="label">Qualidade / Taxa:</span>
        <select id="qualitySelect">
          <option value="1080p60">1080p (60 FPS - Fluido)</option>
          <option value="1080p30" selected>1080p (30 FPS - Padrão)</option>
          <option value="720p60">720p (60 FPS - Jogos)</option>
          <option value="720p30">720p (30 FPS - Econômico)</option>
        </select>
      </div>
      <div class="opt-row">
        <span class="label">Transmitir Áudio:</span>
        <input type="checkbox" id="chkAudio" checked>
      </div>
    </div>

    <div class="preview-container" id="previewContainer">
      <video id="preview" autoplay muted playsinline></video>
    </div>

    <div class="status-msg" id="statusMsg">Conectando ao projetor...</div>
  </div>

  <footer>LumiCast • 100% Open Source • Rede Local</footer>

  <script>
    let ws = null;
    let peerConnection = null;
    let localStream = null;

    const btnStart = document.getElementById('btnStart');
    const btnStop = document.getElementById('btnStop');
    const badgeStatus = document.getElementById('badgeStatus');
    const badgeText = document.getElementById('badgeText');
    const statusMsg = document.getElementById('statusMsg');
    const previewContainer = document.getElementById('previewContainer');
    const previewVideo = document.getElementById('preview');

    function updateStatus(text, isActive = false, isError = false) {
      statusMsg.textContent = text;
      badgeText.textContent = isActive ? 'Transmitindo' : (isError ? 'Erro' : 'Conectado');
      badgeStatus.className = 'badge ' + (isActive ? 'active' : '');
    }

    // Connect to WebSocket signaling server on projector
    function connectSignaling() {
      const loc = window.location;
      const wsUrl = (loc.protocol === 'https:' ? 'wss://' : 'ws://') + loc.host + '/ws';
      
      ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        updateStatus('Pronto para iniciar espelhamento');
      };

      ws.onmessage = async (event) => {
        try {
          const data = JSON.parse(event.data);
          if (data.type === 'answer') {
            await peerConnection.setRemoteDescription(new RTCSessionDescription(data.sdp));
            updateStatus('Espelhando na tela do projetor!', true);
          } else if (data.type === 'candidate') {
            if (peerConnection && data.candidate) {
              await peerConnection.addIceCandidate(new RTCIceCandidate(data.candidate));
            }
          }
        } catch (e) {
          console.error('Erro ao processar mensagem do projetor:', e);
        }
      };

      ws.onclose = () => {
        updateStatus('Desconectado do projetor. Reconectando...');
        setTimeout(connectSignaling, 2000);
      };

      ws.onerror = () => {
        updateStatus('Erro na conexão com o projetor', false, true);
      };
    }

    async function startMirroring() {
      const quality = document.getElementById('qualitySelect').value;
      const includeAudio = document.getElementById('chkAudio').checked;

      let width = 1920, height = 1080, frameRate = 30;
      if (quality === '1080p60') { frameRate = 60; }
      else if (quality === '720p60') { width = 1280; height = 720; frameRate = 60; }
      else if (quality === '720p30') { width = 1280; height = 720; frameRate = 30; }

      const displayMediaOptions = {
        video: {
          width: { ideal: width },
          height: { ideal: height },
          frameRate: { ideal: frameRate, max: 60 }
        },
        audio: includeAudio
      };

      try {
        if (!navigator.mediaDevices || !navigator.mediaDevices.getDisplayMedia) {
          alert('Seu navegador não suporta captura de tela direta. Use o Chrome ou Safari atualizados.');
          return;
        }

        updateStatus('Aguardando permissão de tela...');
        localStream = await navigator.mediaDevices.getDisplayMedia(displayMediaOptions);
        
        previewVideo.srcObject = localStream;
        previewContainer.style.display = 'block';

        btnStart.style.display = 'none';
        btnStop.style.display = 'flex';

        // When user stops sharing via browser bar
        localStream.getVideoTracks()[0].onended = () => {
          stopMirroring();
        };

        // Create WebRTC PeerConnection
        const config = {
          iceServers: [
            { urls: 'stun:stun.l.google.com:19302' }
          ]
        };
        peerConnection = new RTCPeerConnection(config);

        // Add tracks
        localStream.getTracks().forEach(track => peerConnection.addTrack(track, localStream));

        // ICE candidates
        peerConnection.onicecandidate = (event) => {
          if (event.candidate && ws && ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: 'candidate',
              candidate: event.candidate
            }));
          }
        };

        // Create SDP Offer
        const offer = await peerConnection.createOffer({
          offerToReceiveVideo: false,
          offerToReceiveAudio: false
        });
        await peerConnection.setLocalDescription(offer);

        if (ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({
            type: 'offer',
            sdp: offer
          }));
          updateStatus('Negociando com o projetor...');
        } else {
          updateStatus('Erro: sem conexão com o projetor', false, true);
        }

      } catch (err) {
        console.error('Erro ao iniciar espelhamento:', err);
        updateStatus('Espelhamento cancelado ou não permitido', false, true);
        stopMirroring();
      }
    }

    function stopMirroring() {
      if (localStream) {
        localStream.getTracks().forEach(track => track.stop());
        localStream = null;
      }
      if (peerConnection) {
        peerConnection.close();
        peerConnection = null;
      }
      previewContainer.style.display = 'none';
      btnStart.style.display = 'flex';
      btnStop.style.display = 'none';
      
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'stop' }));
      }
      updateStatus('Pronto para iniciar espelhamento');
    }

    // Auto connect on load
    window.addEventListener('load', connectSignaling);
  </script>
</body>
</html>
''';
