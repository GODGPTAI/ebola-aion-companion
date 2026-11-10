import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const EbolaApp());

const _red = Color(0xFFD81927);
const _ink = Color(0xFF171923);
const _pale = Color(0xFFFFF5F6);

/// No reusable API credentials or bearer tokens are embedded in the APK.
/// Existing website login remains the authoritative account system.
class EbolaApp extends StatelessWidget {
  const EbolaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'EBOLA AION',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF9F9FB),
          colorScheme: ColorScheme.fromSeed(
            seedColor: _red,
            primary: _red,
            surface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: _ink,
            surfaceTintColor: Colors.transparent,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        home: const CompanionHome(),
      );
}

class GlassInfo {
  final String code;
  final String name;
  final String subtitle;
  final String? asset;
  const GlassInfo(this.code, this.name, this.subtitle, [this.asset]);
}

const glassCatalog = <GlassInfo>[
  GlassInfo('G1', 'EBOLA G1 Everyday', 'Everyday AI assistance'),
  GlassInfo('G2', 'EBOLA G2 Vision', 'Camera • Translation • Voice'),
  GlassInfo('G3', 'EBOLA G3 Super Charge', 'Power case • Smart capture', 'assets/images/g3.png'),
  GlassInfo('G4', 'EBOLA G4 Sport Pro', 'Sport • Travel • Video', 'assets/images/g4.png'),
];

class CompanionHome extends StatefulWidget {
  const CompanionHome({super.key});

  @override
  State<CompanionHome> createState() => _CompanionHomeState();
}

class _CompanionHomeState extends State<CompanionHome> {
  final EbolaMockAdapter _demo = EbolaMockAdapter();
  int _page = 0;
  String? _demoDeviceId;
  int? _demoBattery;
  bool _busy = false;

  Future<void> _openSite(String route) async {
    final uri = Uri.https('ebolascan.online', route);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _message('Unable to open website. Try in your browser.');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _connectDemo() async {
    setState(() => _busy = true);
    try {
      final results = await _demo.scan();
      if (results.isEmpty) throw StateError('No simulated device');
      await _demo.connect(results.first.id);
      final battery = await _demo.batteryPercent();
      if (!mounted) return;
      setState(() {
        _demoDeviceId = results.first.id;
        _demoBattery = battery;
      });
      _message('Demo device connected. This is NOT a real Bluetooth connection.');
    } catch (_) {
      _message('Demo connection failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnectDemo() async {
    await _demo.disconnect();
    if (!mounted) return;
    setState(() {
      _demoDeviceId = null;
      _demoBattery = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const names = ['Home', 'My Glasses', 'KRISHNA', 'Account'];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          Image.asset('assets/images/EBOLA.png', height: 39, width: 39),
          const SizedBox(width: 9),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('EBOLA AION', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text('SMART WEARABLE OS', style: TextStyle(fontSize: 10, letterSpacing: 1.2)),
          ]),
        ]),
      ),
      body: SafeArea(
        child: IndexedStack(index: _page, children: [
          _homePage(),
          _devicesPage(),
          _krishnaPage(),
          _accountPage(),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _page,
        onDestinationSelected: (index) => setState(() => _page = index),
        indicatorColor: const Color(0xFFFFD8DB),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.visibility_outlined), selectedIcon: Icon(Icons.visibility), label: 'Glasses'),
          const NavigationDestination(icon: Icon(Icons.mic_none), selectedIcon: Icon(Icons.mic), label: 'KRISHNA'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  Widget _homePage() => ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_red, Color(0xFF760514)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ONE APP. FOUR AI GLASSES.', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.4)),
            const SizedBox(height: 9),
            const Text('Your AI world, on the move.', style: TextStyle(color: Colors.white, fontSize: 26, height: 1.14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('G1 • G2 • G3 • G4 | KRISHNA AI | Secure accounts', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => setState(() => _page = 1),
              icon: const Icon(Icons.smart_toy_outlined), label: const Text('Explore my glasses'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        _notice('Development preview', 'Real glasses pairing and camera controls remain disabled until compatible hardware and SDK are verified.'),
        const SizedBox(height: 20),
        const Text('Four EBOLA models', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...glassCatalog.map((g) => _glassCard(g)),
        const SizedBox(height: 12),
        _actionCard(Icons.dashboard_customize_outlined, 'Existing EBOLA Dashboard', 'Use the established EBOLA account and QR.', () => _openSite('/dashboard.php')),
      ]);

  Widget _glassCard(GlassInfo glass) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFE9E9EE)), borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            SizedBox(width: 86, height: 78, child: glass.asset != null
                ? Image.asset(glass.asset!, fit: BoxFit.contain)
                : Container(
                    decoration: BoxDecoration(color: _pale, borderRadius: BorderRadius.circular(13)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.visibility_outlined, color: _red, size: 31),
                      Text(glass.code, style: const TextStyle(fontWeight: FontWeight.bold, color: _red)),
                    ]),
                  )),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(glass.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(glass.subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              const Text('Hardware validation pending', style: TextStyle(fontSize: 11, color: _red)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ]),
        ),
      );

  Widget _devicesPage() => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('My EBOLA Glasses', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
        const SizedBox(height: 5),
        const Text('Four models • One licence per physical device', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        _notice('Real device integration', 'Bluetooth, firmware identity and hardware attestation are not yet verified. Demo mode is isolated and cannot activate a paid licence.'),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.science_outlined, color: _red), SizedBox(width: 8), Text('Mock Device Lab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
            const SizedBox(height: 10),
            Text(_demoDeviceId == null ? 'No mock device connected' : 'Connected: $_demoDeviceId', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (_demoBattery != null) Text('Simulated battery: $_demoBattery%'),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _busy ? null : (_demoDeviceId == null ? _connectDemo : _disconnectDemo),
              icon: Icon(_demoDeviceId == null ? Icons.bluetooth_searching : Icons.bluetooth_disabled),
              label: Text(_busy ? 'Connecting…' : _demoDeviceId == null ? 'Connect demo device' : 'Disconnect demo'),
            ),
          ])),
        ),
        const SizedBox(height: 18),
        const Text('Real G1–G4 devices', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        const SizedBox(height: 8),
        ...glassCatalog.map((g) => _glassCard(g)),
        const SizedBox(height: 10),
        _actionCard(Icons.verified_user_outlined, 'Device licence & replacement', 'Backend tested. Physical-device registration requires authenticated app session and verified adapter.', () => _message('Live licence controls are disabled until secure sign-in and hardware binding are implemented.')),
      ]);

  Widget _krishnaPage() => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('KRISHNA AI', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        _notice('Use your existing KRISHNA', 'Open the authenticated website. This app does not duplicate the AI backend or store API keys.'),
        const SizedBox(height: 14),
        _actionCard(Icons.record_voice_over_outlined, 'KRISHNA Assistant', 'Existing AI chat and voice features', () => _openSite('/krishna.php')),
        _actionCard(Icons.visibility_outlined, 'EBOLA EYE / DRISHTI', 'Vision and OCR are planned; do not use for safety-critical navigation.', () => _message('DRISHTI hardware camera integration is pending.')),
        _actionCard(Icons.movie_creation_outlined, 'BRAHMA Video Workspace', 'Open existing video AI workspace', () => _openSite('/videoaiworkforce.php')),
      ]);

  Widget _accountPage() => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('My EBOLA Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _notice('Single EBOLA identity', 'Continue using your existing login, sponsor code, Dashboard, wallet and Secure Vault. This first app build opens the official site in your browser.'),
        const SizedBox(height: 12),
        _actionCard(Icons.login, 'Sign in', 'Existing login.php', () => _openSite('/login.php')),
        _actionCard(Icons.dashboard_outlined, 'Dashboard & One QR', 'Existing dashboard.php', () => _openSite('/dashboard.php')),
        _actionCard(Icons.shield_outlined, 'My Secure Vault', 'Vault remains server-side, per-user encrypted', () => _message('Vault app-session integration pending. Use your existing EBOLA account.')),
        _actionCard(Icons.code, 'EBOLA SDK Developer Portal', 'G1–G4 documentation and developer tools', () => _openSite('/developerebolaaiindex.php')),
        const SizedBox(height: 20),
        const Text('GODGPTAI GREENS INNOVATION AND AI TECHNOLOGIES PRIVATE LIMITED', style: TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 4),
        const Text('Companion App v0.1.0 • Development build', style: TextStyle(fontSize: 11, color: Colors.black45)),
      ]);

  Widget _notice(String title, String body) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _pale, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFCED3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, color: _red, size: 22),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(body, style: const TextStyle(fontSize: 12.5, height: 1.35)),
          ])),
        ]),
      );

  Widget _actionCard(IconData icon, String title, String caption, VoidCallback action) => Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          leading: Icon(icon, color: _red),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(caption),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
          onTap: action,
        ),
      );
}
