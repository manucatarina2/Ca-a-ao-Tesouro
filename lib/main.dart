import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const CacaAoTesouroApp());
}

// ─── Constantes ───────────────────────────────────────────────────────────────
const double treasureLat = -23.11443;
const double treasureLng = -45.70780;
const double metrosPorPasso = 0.8;

// Paleta Rosa Premium
const Color rosaPrimario    = Color(0xFFE91E8C); // hot pink
const Color rosaSecundario  = Color(0xFFF06292); // pink claro
const Color rosaEscuro      = Color(0xFFC2185B); // deep pink
const Color roxo            = Color(0xFF9C27B0); // roxo complementar
const Color corFundo1       = Color(0xFF1A0A2E); // fundo escuro
const Color corFundo2       = Color(0xFF2D1B4E); // fundo médio
const Color corQuente       = Color(0xFFFF4500); // vermelho < 50p
const Color corFrio         = Color(0xFF87CEFA); // azul ≥ 50p

class CacaAoTesouroApp extends StatelessWidget {
  const CacaAoTesouroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caça ao Tesouro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: rosaPrimario,
          secondary: rosaSecundario,
        ),
      ),
      home: const TreasureHuntScreen(),
    );
  }
}

// ─── Tela Principal ───────────────────────────────────────────────────────────
class TreasureHuntScreen extends StatefulWidget {
  const TreasureHuntScreen({super.key});

  @override
  State<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends State<TreasureHuntScreen>
    with TickerProviderStateMixin {

  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;

  double _distanciaMetros = double.infinity;
  double _distanciaPassos = double.infinity;
  String _dica           = 'Buscando localização...';
  double _bearingRad     = 0.0;
  bool   _tesouroEncontrado = false;
  bool   _musicaTocando     = false;
  bool   _erroBusca         = false;
  String _msgErro           = '';

  // Cor de indicador (hot/cold)
  Color _indicadorColor = corFrio;

  late AnimationController _arrowSpinCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _particleCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double>   _shimmerAnim;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _arrowSpinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _iniciarLocalizacao();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _arrowSpinCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    _shimmerCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────────────────
  Future<void> _iniciarLocalizacao() async {
    bool ok = await Geolocator.isLocationServiceEnabled();
    if (!ok) {
      setState(() { _erroBusca = true; _msgErro = 'GPS desativado. Ative-o e tente novamente.'; });
      return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      setState(() { _erroBusca = true; _msgErro = 'Permissão de localização negada.'; });
      return;
    }
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position pos) {
    _currentPosition = pos;
    final distM  = Geolocator.distanceBetween(pos.latitude, pos.longitude, treasureLat, treasureLng);
    final passos = distM / metrosPorPasso;
    final bearDeg = Geolocator.bearingBetween(pos.latitude, pos.longitude, treasureLat, treasureLng);

    final String dica;
    final Color cor;
    if (passos < 10)       { dica = '🔥 Muito quente! Está quase lá!'; cor = corQuente; }
    else if (passos < 25)  { dica = '♨️ Quente! Está perto!';           cor = corQuente; }
    else if (passos < 50)  { dica = '🌡️ Morno! Continue procurando.';   cor = corQuente; }
    else                   { dica = '❄️ Frio! Está longe do tesouro.';  cor = corFrio;   }

    final bool enc = passos < 10;
    if (enc && !_tesouroEncontrado) {
      _tesouroEncontrado = true;
      _arrowSpinCtrl.stop();
      _pulseCtrl.repeat(reverse: true);
      _tocarMusica();
    } else if (!enc && _tesouroEncontrado) {
      _tesouroEncontrado = false;
      _pulseCtrl.stop();
      _arrowSpinCtrl.repeat();
      _pararMusica();
    }

    setState(() {
      _distanciaMetros  = distM;
      _distanciaPassos  = passos;
      _dica             = dica;
      _bearingRad       = bearDeg * math.pi / 180.0;
      _indicadorColor   = cor;
      _erroBusca        = false;
    });
  }

  Future<void> _tocarMusica() async {
    if (_musicaTocando) return;
    _musicaTocando = true;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/tesouro.mp3'));
    } catch (e) { debugPrint('Audio error: $e'); }
  }

  Future<void> _pararMusica() async {
    _musicaTocando = false;
    await _audioPlayer.stop();
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo com gradiente escuro-rosa
          _buildBackground(),
          // Partículas decorativas
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context2, _) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
              size: MediaQuery.of(context).size,
            ),
          ),
          // Conteúdo
          SafeArea(
            child: _erroBusca ? _buildErro() : _buildConteudo(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [corFundo1, corFundo2, Color(0xFF1E0A3C)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: _glassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 64, color: rosaPrimario),
              const SizedBox(height: 16),
              Text(_msgErro, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 24),
              _pinkButton(label: 'Tentar novamente', onTap: _iniciarLocalizacao),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    final carregando = _currentPosition == null;
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                if (carregando) _buildCarregando()
                else if (_tesouroEncontrado) _buildTesouroEncontrado()
                else _buildSeta(),
                const SizedBox(height: 20),
                _buildDicaCard(),
                const SizedBox(height: 14),
                if (!carregando) _buildDistanciaCard(),
                const SizedBox(height: 14),
                if (_currentPosition != null) _buildPosicaoCard(),
                const SizedBox(height: 20),
                _buildLegenda(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (context2, _) => ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [rosaPrimario, rosaSecundario, rosaPrimario],
                stops: [0.0, _shimmerAnim.value, 1.0],
              ).createShader(bounds),
              child: const Text(
                '✦ Caça ao Tesouro ✦',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text('PPDM • Exercício de Fixação',
            style: TextStyle(fontSize: 12, color: Colors.white38, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  // ── Seta ─────────────────────────────────────────────────────────────────────
  Widget _buildSeta() {
    return AnimatedBuilder(
      animation: _arrowSpinCtrl,
      builder: (context2, _) {
        final angle = _currentPosition != null
            ? _bearingRad
            : _arrowSpinCtrl.value * 2 * math.pi;
        return Column(
          children: [
            Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [rosaPrimario.withValues(alpha: 0.25), Colors.transparent],
                ),
                border: Border.all(color: rosaPrimario.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: rosaPrimario.withValues(alpha: 0.35),
                      blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: Transform.rotate(
                angle: angle,
                child: Icon(Icons.navigation_rounded, size: 90, color: rosaPrimario),
              ),
            ),
            const SizedBox(height: 10),
            Text('Siga a seta!',
              style: TextStyle(fontSize: 14, color: rosaSecundario.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          ],
        );
      },
    );
  }

  // ── Tesouro Encontrado ───────────────────────────────────────────────────────
  Widget _buildTesouroEncontrado() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context2, _) => Transform.scale(
        scale: _pulseAnim.value,
        child: Column(
          children: [
            Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.amber.withValues(alpha: 0.4),
                           Colors.orange.withValues(alpha: 0.1)],
                ),
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.7),
                      blurRadius: 40, spreadRadius: 10),
                ],
              ),
              child: const Center(child: Text('💰', style: TextStyle(fontSize: 80))),
            ),
            const SizedBox(height: 14),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.amber, Colors.orange, Colors.amber],
              ).createShader(bounds),
              child: const Text('🎉 TESOURO ENCONTRADO! 🎉',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarregando() {
    return Column(
      children: [
        SizedBox(width: 100, height: 100,
          child: CircularProgressIndicator(
            color: rosaPrimario, strokeWidth: 3,
            backgroundColor: rosaPrimario.withValues(alpha: 0.15),
          )),
        const SizedBox(height: 16),
        const Text('Obtendo localização GPS...',
          style: TextStyle(fontSize: 15, color: Colors.white54)),
      ],
    );
  }

  // ── Cards ─────────────────────────────────────────────────────────────────────
  Widget _buildDicaCard() {
    return _glassCard(
      accentColor: rosaPrimario,
      child: Row(
        children: [
          Container(
            width: 4, height: 50,
            decoration: BoxDecoration(
              color: _indicadorColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: _indicadorColor.withValues(alpha: 0.8), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(_dica, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanciaCard() {
    return _glassCard(
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.directions_walk_rounded, color: rosaPrimario, size: 18),
            const SizedBox(width: 6),
            const Text('Distância', style: TextStyle(fontSize: 13, color: Colors.white54, letterSpacing: 1)),
          ]),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [rosaPrimario, rosaSecundario],
            ).createShader(b),
            child: Text(
              _distanciaPassos.isInfinite ? '---' : _distanciaPassos.toStringAsFixed(0),
              style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          Text(
            _distanciaPassos.isInfinite ? '' : 'passos  •  ${_distanciaMetros.toStringAsFixed(1)} m',
            style: const TextStyle(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildPosicaoCard() {
    return _glassCard(
      child: Row(
        children: [
          const Icon(Icons.my_location, color: rosaPrimario, size: 20),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Sua posição', style: TextStyle(fontSize: 12, color: Colors.white38)),
            const SizedBox(height: 4),
            Text(
              'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}\n'
              'Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'monospace'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildLegenda() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendaDot(corFrio, '❄️ ≥ 50 passos'),
        const SizedBox(width: 20),
        _legendaDot(corQuente, '🔥 < 50 passos'),
      ],
    );
  }

  Widget _legendaDot(Color cor, String label) {
    return Row(children: [
      Container(width: 12, height: 12,
        decoration: BoxDecoration(shape: BoxShape.circle, color: cor,
          boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.6), blurRadius: 6)])),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.white38)),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _glassCard({required Widget child, Color? accentColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: (accentColor ?? rosaPrimario).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (accentColor ?? rosaPrimario).withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _pinkButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [rosaPrimario, roxo]),
          boxShadow: [BoxShadow(color: rosaPrimario.withValues(alpha: 0.5), blurRadius: 16)],
        ),
        child: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}

// ─── Painter de partículas ────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  static final List<_Particle> _particles = List.generate(18, (i) => _Particle(i));

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress + p.offset) % 1.0;
      final x = p.x * size.width;
      final y = size.height - (t * (size.height + 40)) + 20;
      final opacity = (math.sin(t * math.pi)).clamp(0.0, 1.0) * 0.5;
      final paint = Paint()
        ..color = Color.lerp(rosaPrimario, rosaSecundario, p.colorFactor)!
            .withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

class _Particle {
  final double x;
  final double offset;
  final double radius;
  final double colorFactor;

  _Particle(int seed)
      : x           = ((seed * 73 + 17) % 100) / 100,
        offset      = ((seed * 37 + 5)  % 100) / 100,
        radius      = 1.5 + ((seed * 11) % 30) / 10,
        colorFactor = ((seed * 29) % 100) / 100;
}
