import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../web_transmitter/transmitter_html.dart';

enum ServerConnectionState {
  waiting,
  mobileConnected,
  mirroring,
  error,
}

class LocalServer {
  HttpServer? _server;
  WebSocket? _currentClient;
  String _localIp = '127.0.0.1';
  int _port = 8080;
  ServerConnectionState _state = ServerConnectionState.waiting;

  // Callbacks for WebRTC signaling
  Function(Map<String, dynamic> offerData)? onOfferReceived;
  Function(Map<String, dynamic> candidateData)? onCandidateReceived;
  Function()? onStreamStopped;
  Function(ServerConnectionState state)? onStateChanged;

  String get localIp => _localIp;
  int get port => _port;
  String get connectionUrl => 'http://$_localIp:$_port';
  ServerConnectionState get state => _state;

  Future<void> start({int preferredPort = 8080}) async {
    await _detectLocalIp();

    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        preferredPort,
        shared: true,
      );
      _port = _server!.port;
    } catch (e) {
      // If preferred port is busy, fallback to any available port
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        0,
        shared: true,
      );
      _port = _server!.port;
    }

    _updateState(ServerConnectionState.waiting);
    _listenRequests();
  }

  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (var interface in interfaces) {
        // Prioritize Wi-Fi or Ethernet interfaces
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final address = addr.address;
            // Prefer common private network IP ranges
            if (address.startsWith('192.168.') ||
                address.startsWith('10.') ||
                address.startsWith('172.')) {
              _localIp = address;
              return;
            }
          }
        }
      }

      // Fallback: take first non-loopback
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        _localIp = interfaces.first.addresses.first.address;
      }
    } catch (e) {
      _localIp = '127.0.0.1';
    }
  }

  void _listenRequests() {
    _server?.listen((HttpRequest request) async {
      final uri = request.uri;

      // Allow Cross-Origin Requests from local devices
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', '*');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      if (uri.path == '/ws') {
        // Upgrade to WebSocket for WebRTC signaling
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          _handleWebSocket(socket);
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
        }
        return;
      }

      // Serve Mobile Transmitter Page
      if (uri.path == '/' || uri.path == '/index.html') {
        request.response.headers.contentType = ContentType.html;
        request.response.write(mobileTransmitterHtml);
        await request.response.close();
        return;
      }

      // Status API
      if (uri.path == '/api/status') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'app': 'LumiCast',
          'version': '1.0.0',
          'state': _state.name,
          'ip': _localIp,
          'port': _port,
        }));
        await request.response.close();
        return;
      }

      // 404
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not Found');
      await request.response.close();
    });
  }

  void _handleWebSocket(WebSocket socket) {
    // If a previous client was connected, clean it up
    _currentClient?.close();
    _currentClient = socket;
    _updateState(ServerConnectionState.mobileConnected);

    socket.listen(
      (message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          final type = data['type'] as String?;

          switch (type) {
            case 'offer':
              _updateState(ServerConnectionState.mirroring);
              onOfferReceived?.call(data);
              break;
            case 'candidate':
              onCandidateReceived?.call(data);
              break;
            case 'stop':
              _updateState(ServerConnectionState.mobileConnected);
              onStreamStopped?.call();
              break;
          }
        } catch (e) {
          // ignore invalid payload
        }
      },
      onDone: () {
        if (_currentClient == socket) {
          _currentClient = null;
          _updateState(ServerConnectionState.waiting);
          onStreamStopped?.call();
        }
      },
      onError: (err) {
        if (_currentClient == socket) {
          _currentClient = null;
          _updateState(ServerConnectionState.waiting);
          onStreamStopped?.call();
        }
      },
      cancelOnError: true,
    );
  }

  void sendToClient(Map<String, dynamic> message) {
    if (_currentClient != null && _currentClient!.readyState == WebSocket.open) {
      _currentClient!.add(jsonEncode(message));
    }
  }

  void _updateState(ServerConnectionState newState) {
    _state = newState;
    onStateChanged?.call(_state);
  }

  Future<void> stop() async {
    await _currentClient?.close();
    await _server?.close(force: true);
    _server = null;
    _currentClient = null;
  }
}
