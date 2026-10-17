# 📽️ LumiCast

> **Espelhador de tela de celular para projetores e TVs inteligentes — 100% Gratuito, Sem Anúncios, Sem Assinaturas e Sem Rastreadores.**

Criado sob medida para dispositivos como o **Projetor T15 PRO (Android 13)** e qualquer periférico ou TV que rode Android.

---

## ✨ Por que o LumiCast?

A maioria dos projetores inteligentes do mercado vêm de fábrica com aplicativos pré-instalados (como AirScreen, EShare, HappyCast) que funcionam como "isca":
* Cobram assinaturas mensais ou semanais caras.
* Exibem anúncios invasivos no meio de apresentações e vídeos.
* Possuem limites de tempo ou travamentos forçados.

**O LumiCast resolve isso de forma definitiva:**
- **Zero Anúncios:** Código 100% limpo, sem monetização oculta.
- **Zero Instalação no Celular:** Não obriga seus amigos, familiares ou clientes a baixar nenhum aplicativo. Basta apontar a câmera para o QR Code na projeção!
- **100% Rede Local:** O áudio e o vídeo trafegam diretamente pela sua rede Wi-Fi via WebRTC de ultra-baixa latência (não depende de servidores externos na internet).
- **Controle Remoto (D-Pad) Nativo:** Feito com interface *10-foot UI* para ser operado com o controle remoto original do projetor.
- **Suporte Multiplataforma:** Transmite do **iPhone (iOS)** e de aparelhos **Android**.

---

## 🏗️ Como Funciona

```
 ┌─────────────────────────────────┐                       ┌────────────────────────────────────────┐
 │   CELULAR (Android ou iPhone)   │                       │          PROJETOR T15 PRO              │
 │                                 │                       │                                        │
 │  1. Aponte a câmera pro QR Code │                       │  1. Abre o app LumiCast                │
 │  2. Abre a página local do app  │ ──[Wi-Fi Local WebRTC]┼─> 2. Mostra QR Code e IP local         │
 │  3. Toca em "Transmitir Tela"   │                       │  3. Decodificação H.264 por Hardware   │
 │                                 │                       │  4. Vídeo Fullscreen em 1080p a 60fps  │
 └─────────────────────────────────┘                       └────────────────────────────────────────┘
```

1. Ao abrir o **LumiCast** no projetor, o app inicia um mini-servidor local embutido em Dart.
2. Uma tela de alta visibilidade (projetada para ambientes de 390 ANSI lumens) exibe um **QR Code** e o endereço IP local.
3. Ao ler o QR Code, o navegador do celular abre a interface de controle do LumiCast.
4. Ao clicar em **"Iniciar Espelhamento"**, uma conexão **WebRTC P2P** é negociada diretamente pela rede local, transmitindo vídeo e áudio em alta definição com aceleração por hardware do Android 13.

---

## 🚀 Como Compilar o APK para o Projetor

Para gerar o arquivo `.apk` final otimizado para o T15 PRO:

```bash
flutter build apk --release
```

O arquivo compilado será gerado em:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📦 Como Instalar no Projetor T15 PRO

Você tem duas maneiras muito simples:

### Opção 1: Via Pendrive USB (Mais fácil)
1. Copie o arquivo `app-release.apk` para um pendrive.
2. Conecte o pendrive na porta USB do T15 PRO.
3. No projetor, abra o aplicativo **Gerenciador de Arquivos** (File Manager).
4. Clique no pendrive, selecione o `app-release.apk` e confirme a instalação.

### Opção 2: Via Wi-Fi / Rede com ADB (Para desenvolvedores)
1. Com o projetor ligado na mesma rede Wi-Fi, ative a *Depuração ADB* nas opções de desenvolvedor do Android 13.
2. No seu computador, execute:
   ```bash
   adb connect <IP_DO_PROJETOR>:5555
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 🛠️ Tecnologias Utilizadas

* **Framework:** [Flutter](https://flutter.dev) (Dart 3.x)
* **Aceleração de Vídeo:** [Flutter WebRTC](https://github.com/flutter-webrtc/flutter-webrtc)
* **Servidor Local Embutido:** Dart `HttpServer` + `WebSocketTransformer`
* **Transmissor Web:** HTML5 + WebRTC `getDisplayMedia` API

---

## 📄 Licença

Distribuído sob a licença **MIT**. Livre para uso pessoal, comercial ou modificação.
