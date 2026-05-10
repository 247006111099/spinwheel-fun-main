// ============================================================
// screens/bubble_spin/bubble_spin_screen.dart
// Pembagian tugas dengan roda spin + pointer dari luar ke dalam
// FIX: pointer sekarang tepat di tepi roda, tidak floating di luar
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BubbleSpinScreen extends StatefulWidget {
  const BubbleSpinScreen({super.key});

  @override
  State<BubbleSpinScreen> createState() => _BubbleSpinScreenState();
}

class _BubbleSpinScreenState extends State<BubbleSpinScreen>
    with TickerProviderStateMixin {
  // ── Tab ─────────────────────────────────────────────────────
  int _tab = 0; // 0=Setup, 1=Spin, 2=Hasil

  // ── Data ────────────────────────────────────────────────────
  final List<String> _members = [];
  final List<String> _tasks = [];
  final _memberCtrl = TextEditingController();
  final _taskCtrl = TextEditingController();
  Map<String, String> _assignments = {};

  // ── Spin ────────────────────────────────────────────────────
  late final AnimationController _spinCtrl;
  double _spinAngle = 0.0;
  double _lastCtrlValue = 0.0;
  double _totalRotation = 0.0;
  bool _isSpinning = false;

  int _currentMemberIdx = -1;
  List<String> _remainingTasks = [];
  List<String> _remainingMembers = [];
  String? _justAssigned;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _spinCtrl.addListener(() {
      if (!mounted) return;
      final delta = _spinCtrl.value - _lastCtrlValue;
      _lastCtrlValue = _spinCtrl.value;
      setState(() => _spinAngle += delta * _totalRotation);
    });
    _spinCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _onSpinDone();
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _memberCtrl.dispose();
    _taskCtrl.dispose();
    super.dispose();
  }

  // ── Add member/task ─────────────────────────────────────────
  void _addMember() {
    final name = _memberCtrl.text.trim();
    if (name.isEmpty) return;
    if (_members.contains(name)) {
      _showSnack('Nama sudah ada!');
      return;
    }
    if (_members.length >= 8) {
      _showSnack('Maksimal 8 anggota!');
      return;
    }
    setState(() => _members.add(name));
    _memberCtrl.clear();
    HapticFeedback.lightImpact();
  }

  void _addTask() {
    final task = _taskCtrl.text.trim();
    if (task.isEmpty) return;
    if (_tasks.contains(task)) {
      _showSnack('Tugas sudah ada!');
      return;
    }
    setState(() => _tasks.add(task));
    _taskCtrl.clear();
    HapticFeedback.lightImpact();
  }

  // ── Mulai sesi spin ─────────────────────────────────────────
  void _startSession() {
    if (_members.isEmpty) {
      _showSnack('Tambahkan anggota dulu!');
      return;
    }
    if (_tasks.isEmpty) {
      _showSnack('Tambahkan tugas dulu!');
      return;
    }
    setState(() {
      _assignments = {};
      _remainingTasks = [..._tasks]..shuffle(math.Random());
      _remainingMembers = [..._members]..shuffle(math.Random());
      _currentMemberIdx = 0;
      _justAssigned = null;
      _tab = 1;
    });
  }

  // ── Spin untuk member saat ini ───────────────────────────────
  void _spinForCurrent() {
    if (_isSpinning) return;
    if (_remainingTasks.isEmpty) {
      _finishSession();
      return;
    }
    _totalRotation = math.pi * 2 * (5 + math.Random().nextDouble() * 5);
    _spinCtrl.duration = Duration(
        milliseconds: (3000 + math.Random().nextDouble() * 1000).toInt());
    _lastCtrlValue = 0.0;
    _spinCtrl.reset();
    setState(() {
      _isSpinning = true;
      _justAssigned = null;
    });
    _spinCtrl.animateTo(1.0, curve: Curves.easeOutCubic);
  }

  void _onSpinDone() {
    if (_remainingTasks.isEmpty) return;

    final arc = math.pi * 2 / _remainingTasks.length;
    final normalized =
        ((_spinAngle % (math.pi * 2)) + math.pi * 2) % (math.pi * 2);
    // Pointer di kanan (angle = 0)
    final pointerAngle =
        (math.pi * 2 - normalized) % (math.pi * 2);
    final taskIdx = (pointerAngle / arc).floor() % _remainingTasks.length;
    final assignedTask = _remainingTasks[taskIdx];
    final member = _remainingMembers[_currentMemberIdx];

    HapticFeedback.heavyImpact();

    setState(() {
      _isSpinning = false;
      _justAssigned = assignedTask;
      _assignments[member] =
          (_assignments[member] ?? '') +
              ((_assignments[member] ?? '').isEmpty ? '' : ', ') +
              assignedTask;
      _remainingTasks.removeAt(taskIdx);
    });
  }

  void _nextMember() {
    if (_remainingTasks.isEmpty) {
      _finishSession();
      return;
    }
    final nextIdx = _currentMemberIdx + 1;
    if (nextIdx >= _remainingMembers.length) {
      setState(() {
        _currentMemberIdx = 0;
        _justAssigned = null;
      });
    } else {
      setState(() {
        _currentMemberIdx = nextIdx;
        _justAssigned = null;
      });
    }
  }

  void _finishSession() {
    setState(() => _tab = 2);
  }

  void _reset() {
    setState(() {
      _assignments = {};
      _remainingTasks = [];
      _remainingMembers = [];
      _currentMemberIdx = -1;
      _justAssigned = null;
      _tab = 0;
    });
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

  static const _colors = [
    Color(0xFF4D96FF),
    Color(0xFFFF6B6B),
    Color(0xFF51CF66),
    Color(0xFFFFD43B),
    Color(0xFFCC5DE8),
    Color(0xFFFF922B),
    Color(0xFF20C997),
    Color(0xFFE64980),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🫧 Bubble Spin'),
        actions: [
          if (_tab != 0)
            TextButton(
              onPressed: _reset,
              child: const Text('Reset',
                  style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: [_buildSetup(), _buildSpin(), _buildResult()][_tab],
    );
  }

  // ── TAB 0: Setup ─────────────────────────────────────────────
  Widget _buildSetup() {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Masukkan anggota & tugas, lalu spin roda untuk membagikan tugas satu per satu.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Anggota
          _SectionHeader(
              icon: '👥', title: 'Anggota', count: _members.length),
          const SizedBox(height: 8),
          _InputRow(
              ctrl: _memberCtrl,
              hint: 'Nama anggota...',
              icon: Icons.person_add_outlined,
              onAdd: _addMember),
          const SizedBox(height: 8),
          if (_members.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _members.asMap().entries.map((e) {
                final color = _colors[e.key % _colors.length];
                return Chip(
                  label: Text(e.value,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: color.withOpacity(0.12),
                  side: BorderSide(color: color.withOpacity(0.4)),
                  deleteIcon: Icon(Icons.close, size: 14, color: color),
                  onDeleted: () => setState(() => _members.remove(e.value)),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          // Tugas
          _SectionHeader(
              icon: '📋', title: 'Daftar Tugas', count: _tasks.length),
          const SizedBox(height: 8),
          _InputRow(
              ctrl: _taskCtrl,
              hint: 'Nama tugas...',
              icon: Icons.task_outlined,
              onAdd: _addTask),
          const SizedBox(height: 8),
          if (_tasks.isNotEmpty)
            Column(
              children: _tasks
                  .asMap()
                  .entries
                  .map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text('${e.key + 1}.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        cs.onSurface.withOpacity(0.5),
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(e.value,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500))),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _tasks.remove(e.value)),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 28),

          // Tombol mulai
          GestureDetector(
            onTap: _startSession,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF51CF66), Color(0xFF20C997)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF51CF66).withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Center(
                child: Text('🎲 Mulai Spin Tugas!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── TAB 1: Spin ──────────────────────────────────────────────
  Widget _buildSpin() {
    if (_remainingMembers.isEmpty) return const SizedBox();
    final member = _remainingMembers[_currentMemberIdx];
    final memberColor = _colors[_currentMemberIdx % _colors.length];
    final isDone = _remainingTasks.isEmpty;

    return Column(
      children: [
        // Member indicator
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: memberColor.withOpacity(0.12),
            border: Border(
                bottom:
                    BorderSide(color: memberColor.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: memberColor,
                child: Text(member[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giliran:',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(member,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: memberColor)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: memberColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_remainingTasks.length} tugas tersisa',
                    style: TextStyle(
                        fontSize: 11,
                        color: memberColor,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        // ── Roda + Pointer (di dalam roda, kanan, menunjuk kiri) ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Roda spin
                AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: _BubbleWheelPainter(
                      tasks: isDone ? ['Selesai!'] : _remainingTasks,
                      angle: _spinAngle,
                      colors: _colors,
                    ),
                  ),
                ),

                // Pointer di tepi KANAN dalam roda, menunjuk ke kiri
                // Menggunakan FractionallySizedBox agar responsif
                Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    // Geser ke dalam: pointer berada di tepi dalam kanan
                    widthFactor: 0.5,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CustomPaint(
                        size: const Size(36, 24),
                        painter: _RightPointerPainter(color: memberColor),
                      ),
                    ),
                  ),
                ),

                if (isDone)
                  const Text(
                    '✅\nSemua\nTugas\nTerbagi!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          ),
        ),

        // Result box
        if (_justAssigned != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [memberColor, memberColor.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('📌 ', style: TextStyle(fontSize: 20)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tugas didapat:',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11)),
                      Text(_justAssigned!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Panel bawah
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Column(
            children: [
              if (!isDone && _justAssigned == null)
                GestureDetector(
                  onTap: _isSpinning ? null : _spinForCurrent,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _isSpinning
                          ? null
                          : LinearGradient(colors: [
                              memberColor,
                              memberColor.withOpacity(0.7)
                            ]),
                      color: _isSpinning ? Colors.grey : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _isSpinning
                            ? '🌀 Berputar...'
                            : '🎰 Spin untuk $member!',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                )
              else if (!isDone && _justAssigned != null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _spinForCurrent,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Spin Lagi'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _nextMember,
                        icon:
                            const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                            _currentMemberIdx + 1 >=
                                    _remainingMembers.length
                                ? 'Selesai'
                                : 'Berikutnya'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _finishSession,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Lihat Hasil'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: const Color(0xFF51CF66),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),

              // Progress anggota
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_remainingMembers.length, (i) {
                  final isActive = i == _currentMemberIdx;
                  final isDoneM =
                      _assignments.containsKey(_remainingMembers[i]) &&
                          i < _currentMemberIdx;
                  final color = _colors[i % _colors.length];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDoneM
                          ? color.withOpacity(0.4)
                          : isActive
                              ? color
                              : color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── TAB 2: Hasil ─────────────────────────────────────────────
  Widget _buildResult() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF51CF66), Color(0xFF20C997)]),
          ),
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 4),
              const Text('Pembagian Tugas Selesai!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text(
                  '${_members.length} anggota · ${_tasks.length} tugas',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._assignments.entries
                  .toList()
                  .asMap()
                  .entries
                  .map((e) {
                final idx = _members.indexOf(e.value.key);
                final color =
                    idx >= 0 ? _colors[idx % _colors.length] : _colors[0];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: color,
                        child: Text(e.value.key[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(e.value.key,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: color)),
                            const SizedBox(height: 2),
                            Text(
                                e.value.value.isEmpty
                                    ? '(tidak ada tugas)'
                                    : e.value.value,
                                style:
                                    const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle,
                          color: color.withOpacity(0.6), size: 20),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Mulai Ulang'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final text = _assignments.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n');
                  Clipboard.setData(
                      ClipboardData(text: '📋 Pembagian Tugas:\n$text'));
                  _showSnack('Disalin ke clipboard!');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Salin Hasil'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bubble Wheel Painter ──────────────────────────────────────
class _BubbleWheelPainter extends CustomPainter {
  final List<String> tasks;
  final double angle;
  final List<Color> colors;

  const _BubbleWheelPainter(
      {required this.tasks, required this.angle, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (tasks.isEmpty) return;
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final arc = math.pi * 2 / tasks.length;

    for (int i = 0; i < tasks.length; i++) {
      final startAngle = angle + arc * i;
      final color = colors[i % colors.length];

      // Slice
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arc,
        true,
        Paint()..color = color.withOpacity(0.88),
      );
      // Border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arc,
        true,
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Text
      final textAngle = startAngle + arc / 2;
      final tr = radius * 0.62;
      canvas.save();
      canvas.translate(center.dx + tr * math.cos(textAngle),
          center.dy + tr * math.sin(textAngle));
      canvas.rotate(textAngle + math.pi / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: tasks[i],
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black38, blurRadius: 3)]),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: radius * 0.65);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Center circle
    canvas.drawCircle(center, 16, Paint()..color = Colors.white);
    canvas.drawCircle(
        center,
        16,
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_BubbleWheelPainter old) =>
      old.angle != angle || old.tasks.length != tasks.length;
}

// ── Pointer di tepi KANAN dalam roda, menunjuk ke KIRI ────────
// Ukuran widget: lebar 36, tinggi 24
// Ujung kiri (x=0) menunjuk ke tengah roda. Basis di sisi kanan.
class _RightPointerPainter extends CustomPainter {
  final Color color;
  const _RightPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Shadow
    final shadowPath = Path()
      ..moveTo(0, size.height / 2)      // ujung kiri → menunjuk ke tengah
      ..lineTo(size.width, 0)            // kanan atas
      ..lineTo(size.width, size.height)  // kanan bawah
      ..close();

    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Segitiga utama — ujung menunjuk ke kiri (ke tengah roda)
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_RightPointerPainter old) => old.color != color;
}

// ── Helpers ──────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  final int count;
  const _SectionHeader(
      {required this.icon, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(width: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).colorScheme.primary)),
        ),
      ],
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final VoidCallback onAdd;
  const _InputRow(
      {required this.ctrl,
      required this.hint,
      required this.icon,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 46,
          height: 46,
          child: ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Icon(Icons.add, size: 20),
          ),
        ),
      ],
    );
  }
}