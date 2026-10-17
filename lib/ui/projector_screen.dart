import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../server/local_server.dart';
import '../webrtc/webrtc_manager.dart';

class ProjectorScreen extends StatefulWidget {
  const ProjectorScreen({super.key});

  @override
  State<ProjectorScreen> createState() => _ProjectorScreenState();
}

class _ProjectorScreenState extends State<ProjectorScreen> {
  final LocalServer _server = LocalServer();
  late final WebRtcManager _webrtc;
  bool _isStreaming = false;
  bool _showControlsOverlay = false;
  RTCVideoViewObjectFit _videoFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;

  @override
  void initState() {
    super.initState();
    _webrtc = WebRtcManager(server: _server);
    _initApp();
  }

  Future<void> _initApp() async {
    await _webrtc.initialize();
    _webrtc.onStreamStateChanged = (streaming) {
      if (mounted) {
        setState(() {
          _isStreaming = streaming;
          _showControlsOverlay = false;
        });
      }
    };

    _server.onStateChanged = (_) {
      if (mounted) setState(() {});
    };

    await _server.start();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _webrtc.dispose();
    _server.stop();
    super.dispose();
  }

  void _toggleVideoFit() {
    setState(() {
      _videoFit = _videoFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
          ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
          : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // OK / Enter button on TV remote
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              if (_isStreaming) {
                setState(() => _showControlsOverlay = !_showControlsOverlay);
                return KeyEventResult.handled;
              }
            }
            // Back button on TV remote
            if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.backspace) {
              if (_isStreaming) {
                _server.sendToClient({'type': 'stop'});
                setState(() => _isStreaming = false);
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: _isStreaming ? _buildVideoPlayerView() : _buildWaitingLobbyView(),
      ),
    );
  }

  Widget _buildVideoPlayerView() {
    return Stack(
      children: [
        // Video View
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: RTCVideoView(
              _webrtc.renderer,
              objectFit: _videoFit,
            ),
          ),
        ),

        // Optional Quick Remote Overlay
        if (_showControlsOverlay)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _toggleVideoFit,
                      icon: const Icon(Icons.aspect_ratio),
                      label: Text(_videoFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
                          ? 'Ajustar: Tela Cheia (Cortar bordas)'
                          : 'Ajustar: Proporção Original'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _server.sendToClient({'type': 'stop'});
                        setState(() => _isStreaming = false);
                      },
                      icon: const Icon(Icons.stop_screen_share),
                      label: const Text('Encerrar Espelhamento'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWaitingLobbyView() {
    final url = _server.connectionUrl;

    return Row(
      children: [
        // Left Column: Instructions and details
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cast_connected,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LumiCast',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Espelhador Livre e Sem Anúncios para Projetores',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Step-by-step guidance
                _buildStepCard(
                  step: '1',
                  icon: Icons.wifi,
                  title: 'Mesma Rede Wi-Fi',
                  subtitle: 'Certifique-se de que o celular está conectado na mesma rede deste projetor.',
                ),
                const SizedBox(height: 14),
                _buildStepCard(
                  step: '2',
                  icon: Icons.qr_code_scanner,
                  title: 'Aponte a Câmera',
                  subtitle: 'Abra a câmera do seu celular (iPhone ou Android) e aponte para o QR Code.',
                ),
                const SizedBox(height: 14),
                _buildStepCard(
                  step: '3',
                  icon: Icons.play_circle_fill,
                  title: 'Toque em "Iniciar Espelhamento"',
                  subtitle: 'Sua tela será projetada instantaneamente em tempo real.',
                ),

                const SizedBox(height: 28),

                // Manual connection IP box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Icon(Icons.language, color: Colors.white60, size: 20),
                      const Text(
                        'Ou acesse pelo navegador: ',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      SelectableText(
                        url,
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Column: Big Crisp QR Code Card
        Expanded(
          flex: 4,
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  const Color(0xFF1E293B).withValues(alpha: 0.6),
                  const Color(0xFF0F172A).withValues(alpha: 0.9),
                ],
              ),
              border: const Border(
                left: BorderSide(color: Colors.white10, width: 1),
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 35,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: url,
                        version: QrVersions.auto,
                        size: 220.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _server.state == ServerConnectionState.mobileConnected
                                  ? 'Celular conectado • Pronto para transmitir'
                                  : 'Aguardando leitura do QR Code...',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'T15 PRO Android 13 • 1080p 60fps Ready',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String step,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: const Color(0xFF60A5FA)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
