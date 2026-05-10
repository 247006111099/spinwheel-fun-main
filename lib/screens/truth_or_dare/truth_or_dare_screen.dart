// ============================================================
// screens/truth_or_dare/truth_or_dare_screen.dart
// Spin roda Truth or Dare dengan kategori & animasi
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TruthOrDareScreen extends StatefulWidget {
  const TruthOrDareScreen({super.key});

  @override
  State<TruthOrDareScreen> createState() => _TruthOrDareScreenState();
}

class _TruthOrDareScreenState extends State<TruthOrDareScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _spinAngle = 0.0;
  double _lastCtrlValue = 0.0;
  double _totalRotation = 0.0;
  bool _isSpinning = false;
  String?_currentQuestion;
  bool _isCurrentTruth = true;
    
  final List<String> _players = [];
  final _playerCtrl = TextEditingController();
  int? _currentPlayer;

  static const _truthQuestions = [
    'Apa hal paling memalukan yang pernah kamu lakukan?',
    'Siapa yang kamu suka di grup ini?',
    'Apa kebohongan terbesar yang pernah kamu ucapkan?',
    'Kapan terakhir kali kamu nangis dan kenapa?',
    'Apa hal yang paling kamu takutin?',
    'Siapa orang yang paling kamu rindukan?',
    'Apa rahasia yang belum pernah kamu ceritain ke siapapun?',
    'Apa hal yang paling kamu sesali dalam hidup?',
    'Kamu pernah ghosting seseorang? Kenapa?',
    'Apa mimpi yang paling aneh yang pernah kamu alami?',
  ];

  static const _dareActions = [
    'Lakukan 20 push-up sekarang!',
    'Nyanyikan lagu favorit kamu dengan suara keras selama 30 detik!',
    'Kirimin pesan "I miss you" ke kontak pertama di HP kamu!',
    'Lakukan joget TikTok selama 1 menit!',
    'Foto selfie aneh dan jadikan foto profil selama 1 jam!',
    'Telepon seseorang dan bilang kamu suka dia!',
    'Minum 1 gelas air dalam 10 detik!',
    'Lakukan impression orang lain di grup ini!',
    'Ceritakan lelucon terburuk yang kamu tau!',
    'Biarkan orang lain posting status apapun dari HP kamu!',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _ctrl.addListener(() {
      if (!mounted) return;
      final delta = _ctrl.value - _lastCtrlValue;
      _lastCtrlValue = _ctrl.value;
      setState(() => _spinAngle += delta * _totalRotation);
    });
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _onSpinDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _playerCtrl.dispose();
    super.dispose();
  }

  void _startSpin() {
    if (_isSpinning) return;
    if (_players.length < 2) {
      _showSnack('Tambahkan minimal 2 pemain!');
      return;
    }
    _totalRotation = math.pi * 2 * (5 + math.Random().nextDouble() * 5);
    _ctrl.duration = Duration(
        milliseconds: (4000 + math.Random().nextDouble() * 1000).toInt());
    _lastCtrlValue = 0.0;
    _ctrl.reset();
    setState(() {
      _isSpinning = true;
      _currentQuestion = null;
    });
    _ctrl.animateTo(1.0, curve: Curves.easeOutCubic);
  }

  void _onSpinDone() {
    if (_players.isEmpty) return;
    final arc = math.pi * 2 / _players.length;
    final normalized =
        ((_spinAngle % (math.pi * 2)) + math.pi * 2) % (math.pi * 2);
    final pointerAngle = (math.pi * 2 - normalized) % (math.pi * 2);
    final playerIndex = (pointerAngle / arc).floor() % _players.length;

    final rng = math.Random();
    final isTruth = rng.nextBool();
    final question = isTruth
        ? _truthQuestions[rng.nextInt(_truthQuestions.length)]
        : _dareActions[rng.nextInt(_dareActions.length)];

    HapticFeedback.heavyImpact();
    setState(() {
      _isSpinning = false;
      _currentPlayer = playerIndex;
      _isCurrentTruth = isTruth;
      _currentQuestion = question;
    });

    _showResultDialog(_players[playerIndex], isTruth, question);
  }

  void _showResultDialog(String player, bool isTruth, String question) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isTruth ? '🤔' : '😈',
                  style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(
                player,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isTruth
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTruth ? 'TRUTH' : 'DARE',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isTruth ? Colors.blue : Colors.red,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isTruth
                        ? [const Color(0xFF4D96FF), const Color(0xFF0066CC)]
                        : [const Color(0xFFFF6B6B), const Color(0xFFCC0000)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  question,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _startSpin();
                      },
                      child: const Text('Spin Lagi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPlayer() {
    final name = _playerCtrl.text.trim();
    if (name.isEmpty) return;
    if (_players.contains(name)) {
      _showSnack('Nama sudah ada!');
      return;
    }
    if (_players.length >= 10) {
      _showSnack('Maksimal 10 pemain!');
      return;
    }
    setState(() => _players.add(name));
    _playerCtrl.clear();
    HapticFeedback.lightImpact();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
  }

  static const _playerColors = [
    Color(0xFF4D96FF), Color(0xFFFF6B6B), Color(0xFF51CF66),
    Color(0xFFFFD43B), Color(0xFFCC5DE8), Color(0xFFFF922B),
    Color(0xFF20C997), Color(0xFFE64980), Color(0xFF74C0FC), Color(0xFFA9E34B),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤔 Truth or Dare'),
      ),
      body: Column(
        children: [
          // Roda spin pemain
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: CustomPaint(
                            painter: _TodWheelPainter(
                              players: _players,
                              angle: _spinAngle,
                              highlightIndex: _currentPlayer,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: SizedBox(
                            width: 30,
                            height: 22,
                            child: CustomPaint(
                              painter: _PointerPainter(),
                            ),
                          ),
                        ),
                        if (_players.isEmpty)
                          const Text(
                            'Tambahkan pemain\ndi bawah',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _startSpin,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _isSpinning
                            ? null
                            : const LinearGradient(colors: [
                                Color(0xFF4D96FF),
                                Color(0xFFFF6B6B),
                              ]),
                        color: _isSpinning ? Colors.grey : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _isSpinning ? '🌀 Berputar...' : '🎲 SPIN!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panel pemain
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _playerCtrl,
                          decoration: InputDecoration(
                            hintText: 'Nama pemain...',
                            prefixIcon: const Icon(Icons.person_add_outlined,
                                size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          onSubmitted: (_) => _addPlayer(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _addPlayer,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Icon(Icons.add, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 140,
                  child: _players.isEmpty
                      ? const Center(
                          child: Text('Belum ada pemain',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          itemCount: _players.length,
                          itemBuilder: (_, i) {
                            final color =
                                _playerColors[i % _playerColors.length];
                            final isActive = i == _currentPlayer;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(isActive ? 0.2 : 0.07),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: color.withOpacity(
                                        isActive ? 0.6 : 0.2)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: color,
                                    child: Text(
                                      _players[i][0].toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_players[i],
                                        style: TextStyle(
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 13,
                                        )),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _players.removeAt(i)),
                                    child: const Icon(Icons.close,
                                        size: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
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

// ── Wheel Painter untuk ToD ───────────────────────────────────
class _TodWheelPainter extends CustomPainter {
  final List<String> players;
  final double angle;
  final int? highlightIndex;

  static const _colors = [
    Color(0xFF4D96FF), Color(0xFFFF6B6B), Color(0xFF51CF66),
    Color(0xFFFFD43B), Color(0xFFCC5DE8), Color(0xFFFF922B),
    Color(0xFF20C997), Color(0xFFE64980), Color(0xFF74C0FC), Color(0xFFA9E34B),
  ];

  const _TodWheelPainter(
      {required this.players, required this.angle, this.highlightIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (players.isEmpty) {
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
      return;
    }
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final arc = math.pi * 2 / players.length;

    for (int i = 0; i < players.length; i++) {
      final startAngle = angle + arc * i;
      final color = _colors[i % _colors.length];
      final isHighlight = i == highlightIndex;

      final paint = Paint()
        ..color = isHighlight ? color : color.withOpacity(0.85)
        ..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, arc, true, paint);

      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, arc, true, borderPaint);

      final textAngle = startAngle + arc / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + math.pi / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: players[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight:
                isHighlight ? FontWeight.w800 : FontWeight.w600,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: radius * 0.7);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, centerPaint);
    final centerBorder = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 18, centerBorder);
  }

  @override
  bool shouldRepaint(_TodWheelPainter old) =>
      old.angle != angle || old.highlightIndex != highlightIndex;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height / 2)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter _) => false;
}
