import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../server/local_server.dart';

class WebRtcManager {
  final LocalServer server;
  final RTCVideoRenderer renderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;
  bool _isInitialized = false;

  Function(bool isReceiving)? onStreamStateChanged;

  WebRtcManager({required this.server});

  Future<void> initialize() async {
    if (_isInitialized) return;
    await renderer.initialize();
    _isInitialized = true;

    // Attach signaling callbacks
    server.onOfferReceived = _handleRemoteOffer;
    server.onCandidateReceived = _handleRemoteCandidate;
    server.onStreamStopped = _handleStreamStopped;
  }

  Future<void> _handleRemoteOffer(Map<String, dynamic> data) async {
    try {
      await _cleanupPeer();

      // Configure Peer Connection (using local STUN + LAN direct host candidates)
      final configuration = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'}
        ],
        'sdpSemantics': 'unified-plan'
      };

      _peerConnection = await createPeerConnection(configuration);

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          renderer.srcObject = _remoteStream;
          onStreamStateChanged?.call(true);
        }
      };

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        server.sendToClient({
          'type': 'candidate',
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }
        });
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _handleStreamStopped();
        }
      };

      // Set Remote Description (Offer from phone)
      final sdpMap = data['sdp'] as Map<String, dynamic>;
      final remoteDesc = RTCSessionDescription(
        sdpMap['sdp'] as String,
        sdpMap['type'] as String,
      );
      await _peerConnection!.setRemoteDescription(remoteDesc);

      // Create Answer
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveVideo': 1,
        'offerToReceiveAudio': 1,
      });
      await _peerConnection!.setLocalDescription(answer);

      // Send Answer back to phone
      server.sendToClient({
        'type': 'answer',
        'sdp': {
          'type': answer.type,
          'sdp': answer.sdp,
        }
      });
    } catch (e) {
      _handleStreamStopped();
    }
  }

  Future<void> _handleRemoteCandidate(Map<String, dynamic> data) async {
    try {
      if (_peerConnection != null) {
        final candMap = data['candidate'] as Map<String, dynamic>;
        final candidate = RTCIceCandidate(
          candMap['candidate'] as String?,
          candMap['sdpMid'] as String?,
          candMap['sdpMLineIndex'] as int?,
        );
        await _peerConnection!.addCandidate(candidate);
      }
    } catch (e) {
      // Candidate error
    }
  }

  void _handleStreamStopped() {
    renderer.srcObject = null;
    _remoteStream = null;
    _cleanupPeer();
    onStreamStateChanged?.call(false);
  }

  Future<void> _cleanupPeer() async {
    try {
      await _peerConnection?.close();
    } catch (_) {}
    _peerConnection = null;
  }

  Future<void> dispose() async {
    await _cleanupPeer();
    await renderer.dispose();
  }
}
