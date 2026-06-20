import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BeastCarApp());
}

class BeastCarApp extends StatelessWidget {
  const BeastCarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeastCar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFF6B00),
          surface: Color(0xFF12121A),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
//  SPLASH SCREEN
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BluetoothConnectScreen()));
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.5),
                            blurRadius: 60, spreadRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.directions_car_rounded,
                        size: 80, color: Color(0xFF00E5FF)),
                  ),
                  const SizedBox(height: 24),
                  Text('BEAST CAR',
                      style: GoogleFonts.orbitron(
                          fontSize: 36, fontWeight: FontWeight.w900,
                          color: const Color(0xFF00E5FF), letterSpacing: 8)),
                  const SizedBox(height: 8),
                  Text('v4 ULTRA EDITION',
                      style: GoogleFonts.orbitron(
                          fontSize: 13, color: const Color(0xFFFF6B00),
                          letterSpacing: 4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  BLUETOOTH CONNECT SCREEN
// ============================================================
class BluetoothConnectScreen extends StatefulWidget {
  const BluetoothConnectScreen({super.key});
  @override
  State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends State<BluetoothConnectScreen> {
  List<ScanResult> _devices = [];
  bool _scanning = false;
  String _status = 'Scan karo devices dhundhne ke liye';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _scan() async {
    setState(() { _scanning = true; _status = 'Scanning...'; _devices = []; });
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      FlutterBluePlus.scanResults.listen((results) {
        if (mounted) setState(() => _devices = results);
      });
      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
      setState(() { _status = '${_devices.length} devices mile'; _scanning = false; });
    } catch (e) {
      setState(() { _status = 'Error: $e'; _scanning = false; });
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _status = '${device.platformName} se connect ho raha hai...');
    try {
      await device.connect();
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? writeChar;
      for (var s in services) {
        for (var c in s.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            writeChar = c;
            break;
          }
        }
        if (writeChar != null) break;
      }
      if (mounted && writeChar != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ControllerScreen(
            device: device,
            characteristic: writeChar!,
            deviceName: device.platformName.isNotEmpty ? device.platformName : 'BeastCar',
          ),
        ));
      }
    } catch (e) {
      setState(() => _status = 'Connect nahi hua: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('BLUETOOTH', style: GoogleFonts.orbitron(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  color: const Color(0xFF00E5FF), letterSpacing: 4)),
              Text('CONNECT', style: GoogleFonts.orbitron(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 4)),
              const SizedBox(height: 8),
              Text(_status, style: GoogleFonts.spaceMono(
                  color: const Color(0xFFFF6B00), fontSize: 13)),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _scanning ? null : _scan,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0080FF)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.35),
                        blurRadius: 24, spreadRadius: 2)],
                  ),
                  child: Center(child: _scanning
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('SCAN KARO', style: GoogleFonts.orbitron(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: 3))),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _devices.isEmpty
                    ? Center(child: Text('Koi device nahi mila\nBluetooth on karo aur scan karo',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceMono(color: Colors.white38, fontSize: 14)))
                    : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (_, i) {
                          final d = _devices[i].device;
                          final name = d.platformName.isNotEmpty ? d.platformName : 'Unknown';
                          final isBeastCar = name.toLowerCase().contains('beast') ||
                              name.toLowerCase().contains('car') ||
                              name.toLowerCase().contains('esp');
                          return GestureDetector(
                            onTap: () => _connect(d),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isBeastCar
                                    ? const Color(0xFF00E5FF).withOpacity(0.08)
                                    : const Color(0xFF12121A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isBeastCar
                                        ? const Color(0xFF00E5FF).withOpacity(0.5)
                                        : Colors.white12),
                              ),
                              child: Row(children: [
                                Icon(Icons.bluetooth_rounded,
                                    color: isBeastCar ? const Color(0xFF00E5FF) : Colors.white38),
                                const SizedBox(width: 16),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: GoogleFonts.orbitron(
                                        fontSize: 15, fontWeight: FontWeight.w700,
                                        color: isBeastCar ? const Color(0xFF00E5FF) : Colors.white)),
                                    Text(d.remoteId.toString(),
                                        style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.white38)),
                                  ],
                                )),
                                if (isBeastCar)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B00).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.5)),
                                    ),
                                    child: Text('BEAST', style: GoogleFonts.orbitron(
                                        fontSize: 10, color: const Color(0xFFFF6B00),
                                        fontWeight: FontWeight.w700)),
                                  ),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  MAIN CONTROLLER SCREEN
// ============================================================
class ControllerScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;
  final String deviceName;
  const ControllerScreen({super.key, required this.device, required this.characteristic, required this.deviceName});
  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> with TickerProviderStateMixin {
  String _currentMode = 'MANUAL';
  double _speed = 180;
  bool _whiteLed = false, _blueLed = false, _ledEffect = false;
  bool _connected = true;
  String _btLog = 'Connected!';
  List<String> _logLines = [];
  Offset _joyOffset = Offset.zero;
  String _lastCmd = 's';
  int _tab = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final List<Map<String, dynamic>> _modes = [
    {'cmd': 'M', 'name': 'MANUAL',   'icon': Icons.gamepad_rounded,         'color': Color(0xFF00E5FF)},
    {'cmd': 'O', 'name': 'OBSTACLE', 'icon': Icons.warning_amber_rounded,    'color': Color(0xFFFF6B00)},
    {'cmd': 'T', 'name': 'FOLLOW',   'icon': Icons.follow_the_signs_rounded, 'color': Color(0xFF00FF88)},
    {'cmd': 'C', 'name': 'CRUISE',   'icon': Icons.speed_rounded,            'color': Color(0xFFFFD700)},
    {'cmd': 'P', 'name': 'PATROL',   'icon': Icons.security_rounded,         'color': Color(0xFF9C27B0)},
    {'cmd': 'S', 'name': 'SECURITY', 'icon': Icons.camera_indoor_rounded,    'color': Color(0xFFFF1744)},
    {'cmd': 'R', 'name': 'RADAR',    'icon': Icons.radar_rounded,            'color': Color(0xFF00BCD4)},
    {'cmd': 'E', 'name': 'EXPLORE',  'icon': Icons.explore_rounded,          'color': Color(0xFF4CAF50)},
    {'cmd': 'Y', 'name': 'MEMORY',   'icon': Icons.memory_rounded,           'color': Color(0xFF607D8B)},
    {'cmd': 'K', 'name': 'PARKING',  'icon': Icons.local_parking_rounded,    'color': Color(0xFF2196F3)},
    {'cmd': 'G', 'name': 'GARAGE',   'icon': Icons.garage_rounded,           'color': Color(0xFF795548)},
    {'cmd': 'Z', 'name': 'ZIGZAG',   'icon': Icons.swap_horiz_rounded,       'color': Color(0xFFE91E63)},
    {'cmd': 'I', 'name': 'DRIFT',    'icon': Icons.rotate_right_rounded,     'color': Color(0xFFFF5722)},
    {'cmd': 'D', 'name': 'RECORD',   'icon': Icons.fiber_manual_record,      'color': Color(0xFFF44336)},
    {'cmd': 'L', 'name': 'REPLAY',   'icon': Icons.replay_rounded,           'color': Color(0xFF8BC34A)},
    {'cmd': 'N', 'name': 'NIGHT',    'icon': Icons.nightlight_rounded,       'color': Color(0xFF3F51B5)},
    {'cmd': 'Q', 'name': 'SPRINT',   'icon': Icons.flash_on_rounded,         'color': Color(0xFFFFEB3B)},
    {'cmd': 'H', 'name': 'HOME',     'icon': Icons.home_rounded,             'color': Color(0xFF009688)},
    {'cmd': 'J', 'name': 'DANCE',    'icon': Icons.music_note_rounded,       'color': Color(0xFFFF4081)},
    {'cmd': '2', 'name': 'MAZE',     'icon': Icons.grid_4x4_rounded,         'color': Color(0xFFCDDC39)},
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    widget.device.connectionState.listen((state) {
      if (mounted) setState(() => _connected = state == BluetoothConnectionState.connected);
    });
    _send('V${_speed.toInt()}');
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    widget.device.disconnect();
    super.dispose();
  }

  Future<void> _send(String cmd) async {
    if (!_connected) return;
    try {
      await widget.characteristic.write(utf8.encode('$cmd\n'), withoutResponse: true);
      if (mounted) setState(() {
        _btLog = cmd;
        _logLines.insert(0, cmd);
        if (_logLines.length > 50) _logLines.removeLast();
      });
    } catch (_) {}
  }

  void _setMode(String cmd, String name) {
    setState(() => _currentMode = name);
    _send(cmd);
    HapticFeedback.mediumImpact();
  }

  void _onJoyUpdate(Offset offset, double maxR) {
    setState(() => _joyOffset = offset);
    final dx = offset.dx / maxR;
    final dy = offset.dy / maxR;
    String cmd = 's';
    if (dx.abs() < 0.25 && dy.abs() < 0.25) cmd = 's';
    else if (dy < -0.3 && dx.abs() < 0.5) cmd = 'F';
    else if (dy > 0.3 && dx.abs() < 0.5) cmd = 'B';
    else if (dx < -0.3) cmd = 'l';
    else if (dx > 0.3) cmd = 'r';
    if (cmd != _lastCmd) { _lastCmd = cmd; _send(cmd); if (cmd != 's') HapticFeedback.lightImpact(); }
  }

  void _onJoyEnd() { setState(() => _joyOffset = Offset.zero); _lastCmd = 's'; _send('s'); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(child: Column(children: [
        _buildTopBar(),
        _buildTabBar(),
        Expanded(child: _buildTabContent()),
      ])),
    );
  }

  Widget _buildTopBar() {
    final modeData = _modes.firstWhere((m) => m['name'] == _currentMode, orElse: () => _modes[0]);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF12121A),
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06)))),
      child: Row(children: [
        AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Transform.scale(
          scale: _connected ? _pulseAnim.value : 1.0,
          child: Icon(Icons.directions_car_rounded,
              color: _connected ? const Color(0xFF00E5FF) : Colors.red, size: 28),
        )),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BEAST CAR', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
          Text(_connected ? widget.deviceName : 'DISCONNECTED',
              style: GoogleFonts.spaceMono(fontSize: 10, color: _connected ? const Color(0xFF00FF88) : Colors.red)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (modeData['color'] as Color).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (modeData['color'] as Color).withOpacity(0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(modeData['icon'] as IconData, size: 14, color: modeData['color'] as Color),
            const SizedBox(width: 6),
            Text(_currentMode, style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.w700, color: modeData['color'] as Color)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      {'icon': Icons.gamepad_rounded, 'label': 'DRIVE'},
      {'icon': Icons.grid_view_rounded, 'label': 'MODES'},
      {'icon': Icons.lightbulb_rounded, 'label': 'LED'},
      {'icon': Icons.terminal_rounded, 'label': 'LOG'},
    ];
    return Container(
      color: const Color(0xFF12121A),
      child: Row(children: List.generate(tabs.length, (i) {
        final active = _tab == i;
        return Expanded(child: GestureDetector(
          onTap: () { setState(() => _tab = i); HapticFeedback.selectionClick(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(
                color: active ? const Color(0xFF00E5FF) : Colors.transparent, width: 2))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(tabs[i]['icon'] as IconData, size: 20, color: active ? const Color(0xFF00E5FF) : Colors.white38),
              const SizedBox(height: 3),
              Text(tabs[i]['label'] as String, style: GoogleFonts.orbitron(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: active ? const Color(0xFF00E5FF) : Colors.white38)),
            ]),
          ),
        ));
      })),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 0: return _buildDriveTab();
      case 1: return _buildModesTab();
      case 2: return _buildLedTab();
      case 3: return _buildLogTab();
      default: return _buildDriveTab();
    }
  }

  Widget _buildDriveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF12121A), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 14, color: Colors.white38),
            const SizedBox(width: 8),
            Expanded(child: Text(_btLog, style: GoogleFonts.spaceMono(fontSize: 11, color: const Color(0xFF00E5FF)), overflow: TextOverflow.ellipsis)),
          ]),
        ),
        const SizedBox(height: 20),
        _buildSpeedSlider(),
        const SizedBox(height: 24),
        _buildJoystick(),
        const SizedBox(height: 24),
        _buildQuickActions(),
      ]),
    );
  }

  Widget _buildSpeedSlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF12121A), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SPEED', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 2)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFF6B00).withOpacity(0.15), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.4))),
            child: Text('${_speed.toInt()}', style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFFFF6B00))),
          ),
        ]),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF00E5FF), inactiveTrackColor: Colors.white12,
            thumbColor: const Color(0xFFFF6B00),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            overlayColor: const Color(0xFFFF6B00).withOpacity(0.2),
          ),
          child: Slider(value: _speed, min: 60, max: 255, onChanged: (v) { setState(() => _speed = v); _send('V${v.toInt()}'); }),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SLOW', style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white24)),
          Text('FAST', style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white24)),
        ]),
      ]),
    );
  }

  Widget _buildJoystick() {
    const double size = 220;
    const double maxR = 75;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF12121A), borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(children: [
        Text('JOYSTICK', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 2)),
        const SizedBox(height: 16),
        SizedBox(width: size, height: size, child: GestureDetector(
          onPanStart: (d) { final c = Offset(size/2, size/2); final raw = d.localPosition-c; final cl = raw.distance > maxR ? raw*(maxR/raw.distance) : raw; _onJoyUpdate(cl, maxR); },
          onPanUpdate: (d) { final c = Offset(size/2, size/2); final raw = d.localPosition-c; final cl = raw.distance > maxR ? raw*(maxR/raw.distance) : raw; _onJoyUpdate(cl, maxR); },
          onPanEnd: (_) => _onJoyEnd(),
          onPanCancel: () => _onJoyEnd(),
          child: CustomPaint(painter: _JoystickPainter(_joyOffset, maxR)),
        )),
        const SizedBox(height: 8),
        Text(
          _lastCmd == 'F' ? '⬆ FORWARD' : _lastCmd == 'B' ? '⬇ BACKWARD' :
          _lastCmd == 'l' ? '⬅ LEFT' : _lastCmd == 'r' ? '➡ RIGHT' : '● STOP',
          style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w700,
              color: _lastCmd == 's' ? Colors.white38 : const Color(0xFF00E5FF)),
        ),
      ]),
    );
  }

  Widget _buildQuickActions() {
    return Row(children: [
      _quickBtn('STOP', 's', Icons.stop_circle_rounded, Colors.red),
      const SizedBox(width: 12),
      _quickBtn('SPRINT', 'Q', Icons.flash_on_rounded, const Color(0xFFFFEB3B)),
      const SizedBox(width: 12),
      _quickBtn('DANCE', 'J', Icons.music_note_rounded, const Color(0xFFFF4081)),
      const SizedBox(width: 12),
      _quickBtn('HOME', 'H', Icons.home_rounded, const Color(0xFF009688)),
    ]);
  }

  Widget _quickBtn(String label, String cmd, IconData icon, Color color) {
    return Expanded(child: GestureDetector(
      onTap: () { _send(cmd); HapticFeedback.mediumImpact(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.35))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 1)),
        ]),
      ),
    ));
  }

  Widget _buildModesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
      itemCount: _modes.length,
      itemBuilder: (_, i) {
        final m = _modes[i];
        final active = _currentMode == m['name'];
        final color = m['color'] as Color;
        return GestureDetector(
          onTap: () => _setMode(m['cmd'] as String, m['name'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: active ? color.withOpacity(0.2) : const Color(0xFF12121A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: active ? color : Colors.white12, width: active ? 2 : 1),
              boxShadow: active ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16)] : [],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(m['icon'] as IconData, color: active ? color : Colors.white38, size: 28),
              const SizedBox(height: 6),
              Text(m['name'] as String, textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(fontSize: 8, fontWeight: FontWeight.w700,
                      color: active ? color : Colors.white38)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildLedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        _ledToggleCard('WHITE LED', 'Headlights', Icons.light_rounded, Colors.white, _whiteLed, () {
          setState(() => _whiteLed = !_whiteLed); _send(_whiteLed ? 'W' : 'w');
        }),
        const SizedBox(height: 16),
        _ledToggleCard('BLUE LEDs', '5x Blue Lights', Icons.auto_awesome_rounded, const Color(0xFF00E5FF), _blueLed, () {
          setState(() => _blueLed = !_blueLed); _send(_blueLed ? 'U' : 'u');
        }),
        const SizedBox(height: 16),
        _ledToggleCard('LED EFFECTS', 'Chase Animation', Icons.theater_comedy_rounded, const Color(0xFFFF6B00), _ledEffect, () {
          setState(() => _ledEffect = !_ledEffect); _send(_ledEffect ? 'X' : 'x');
        }),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _bigLedBtn('ALL ON', 'A', Icons.lightbulb_rounded, const Color(0xFFFFD700))),
          const SizedBox(width: 16),
          Expanded(child: _bigLedBtn('ALL OFF', 'a', Icons.lightbulb_outline_rounded, Colors.white38)),
        ]),
      ]),
    );
  }

  Widget _ledToggleCard(String title, String subtitle, IconData icon, Color color, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color.withOpacity(0.6) : Colors.white12, width: active ? 2 : 1),
          boxShadow: active ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20)] : [],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56, height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: active ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
            child: Icon(icon, color: active ? color : Colors.white38, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w700, color: active ? color : Colors.white)),
            Text(subtitle, style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.white38)),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52, height: 28,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: active ? color : Colors.white12),
            child: Align(
              alignment: active ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(margin: const EdgeInsets.all(3), width: 22, height: 22,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _bigLedBtn(String label, String cmd, IconData icon, Color color) {
    return GestureDetector(
      onTap: () { _send(cmd); HapticFeedback.mediumImpact(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35))),
        child: Column(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 2)),
        ]),
      ),
    );
  }

  Widget _buildLogTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Text('BLUETOOTH LOG', style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 2)),
          const Spacer(),
          GestureDetector(onTap: () => setState(() => _logLines = []),
              child: Text('CLEAR', style: GoogleFonts.orbitron(fontSize: 11, color: const Color(0xFFFF6B00)))),
        ]),
      ),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _logLines.length,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF12121A), borderRadius: BorderRadius.circular(8)),
          child: Text(_logLines[i], style: GoogleFonts.spaceMono(fontSize: 11,
              color: _logLines[i].contains('ALERT') ? const Color(0xFFFF1744) :
              _logLines[i].contains('DONE') || _logLines[i].contains('READY') ? const Color(0xFF00FF88) :
              const Color(0xFF00E5FF))),
        ),
      )),
    ]);
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset offset;
  final double maxR;
  _JoystickPainter(this.offset, this.maxR);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, maxR + 20, Paint()..color = Colors.white.withOpacity(0.06));
    canvas.drawCircle(center, maxR + 20, Paint()..color = const Color(0xFF00E5FF).withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final grid = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1;
    canvas.drawLine(center + Offset(-(maxR+20), 0), center + Offset(maxR+20, 0), grid);
    canvas.drawLine(center + Offset(0, -(maxR+20)), center + Offset(0, maxR+20), grid);
    final knobPos = center + offset;
    canvas.drawCircle(knobPos, 36, Paint()..color = const Color(0xFF00E5FF).withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    canvas.drawCircle(knobPos, 28, Paint()..shader = RadialGradient(
      colors: [const Color(0xFF00E5FF), const Color(0xFF0050AA)],
    ).createShader(Rect.fromCircle(center: knobPos, radius: 28)));
    canvas.drawCircle(knobPos, 28, Paint()..color = const Color(0xFF00E5FF).withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(knobPos, 6, Paint()..color = Colors.white.withOpacity(0.8));
  }

  @override
  bool shouldRepaint(_JoystickPainter old) => old.offset != offset;
}
