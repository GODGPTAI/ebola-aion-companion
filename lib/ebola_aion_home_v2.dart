// EBOLA AION neon development dashboard. Visual data is NOT simulated hardware telemetry.
// Hardware operations are delegated to the existing camera probe.
import 'package:flutter/material.dart';
import 'ebola_glass_status.dart';

const Color _bg = Color(0xFF080609);
const Color _panel = Color(0xFF190C13);
const Color _red = Color(0xFFFF1739);
const Color _green = Color(0xFF39FF73);
const Color _muted = Color(0xFFC8B8C1);

class EbolaAionHomeV2 extends StatelessWidget {
  final VoidCallback onGlasses;
  final VoidCallback onMainchat;
  final VoidCallback onDashboard;
  final void Function(String) onService;
  final String sessionDuration;
  const EbolaAionHomeV2({super.key, required this.onGlasses,
    required this.onMainchat, required this.onDashboard,
    required this.onService, required this.sessionDuration});

  @override
  Widget build(BuildContext context) => Container(
    color: _bg,
    child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 30), children: [
      _header(), const SizedBox(height: 14),
      ValueListenableBuilder<EbolaGlassStatus>(
        valueListenable: ebolaGlassStatus,
        builder: (_, snapshot, __) => _statusPanel(snapshot)),
      const SizedBox(height: 14),
      _heading('GLASS COMMAND CENTRE', 'Two glass models • actual hardware verification required'),
      ValueListenableBuilder<EbolaGlassStatus>(
        valueListenable: ebolaGlassStatus,
        builder: (_, snapshot, __) => _glassCards(snapshot)),
      const SizedBox(height: 13),
      _quickActions(), const SizedBox(height: 16),
      _heading('ONE QR • ALL POWER', 'Open the original signed-in QR on your dashboard'),
      _qrPanel(), const SizedBox(height: 16),
      _heading('EBOLA AI COMPANY OS', 'All requested modules • existing live services'),
      _featureGrid(context), const SizedBox(height: 16),
      _heading('EBOLA RELIEF 8.5', 'Find an authorized seller; inventory needs server verification'),
      _reliefPanel(), const SizedBox(height: 16),
      _heading('EBOLAPE SERVICES', 'The live website is the source of truth'),
      _services(), const SizedBox(height: 18),
      Row(children: [Expanded(child: _action('EBOLAPE.COM', Icons.travel_explore, () => onService('EBOLAPE'))),
        const SizedBox(width: 8), Expanded(child: _action('DASHBOARD', Icons.dashboard, onDashboard))]),
    ]),
  );

  Widget _header() => _neonBox(child: Column(children: [
    Row(children: [
      Image.asset('assets/images/EBOLA.png', width: 68, height: 68,
        fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, color: _red, size: 50)),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EBOLA AI', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900,
          color: Colors.white, letterSpacing: 1.2)),
        Text('GLASS COMMAND CENTRE', style: TextStyle(color: _red, fontSize: 11,
          fontWeight: FontWeight.w800, letterSpacing: 1)),
        Text('NEON DEVELOPMENT BUILD', style: TextStyle(color: _muted, fontSize: 10)),
      ])),
      const Icon(Icons.memory, color: _green, size: 32),
    ]),
    const SizedBox(height: 8),
    const Text('ONE QR. ALL POWER.', style: TextStyle(color: _green,
      fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
    const SizedBox(height: 3),
    const Text('Scan Once • Open Everything', style: TextStyle(color: _muted, fontSize: 11)),
  ]));

  Widget _statusPanel(EbolaGlassStatus snapshot) => _neonBox(green: true, child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [const Icon(Icons.bluetooth_searching, color: _green),
      SizedBox(width: 8), Expanded(child: Text('AUTO DEVICE TEST', style: TextStyle(
        color: _green, fontWeight: FontWeight.w900, fontSize: 15))),
      _Tag(snapshot.connected ? 'CONNECTED' : 'NOT CONNECTED', green: snapshot.connected)]),
    const SizedBox(height: 10),
    LinearProgressIndicator(value: snapshot.discoveryPercent / 100, minHeight: 7,
      backgroundColor: const Color(0xFF38202A),
      color: _green, borderRadius: const BorderRadius.all(Radius.circular(8))),
    const SizedBox(height: 8),
    Text('DISCOVERY ${snapshot.discoveryPercent}% • ${snapshot.phase}',
      style: const TextStyle(color: _muted, fontSize: 11)),
    const SizedBox(height: 10),
    Wrap(spacing: 6, runSpacing: 7, children: [
      _StateChip('BLE: ${snapshot.connection}', Icons.bluetooth),
      _StateChip('RSSI: ${snapshot.rssi}', Icons.signal_cellular_alt),
      _StateChip('BATTERY: ${snapshot.battery}', Icons.battery_unknown),
      const _StateChip('CAMERA: NOT VERIFIED', Icons.camera_alt_outlined),
      const _StateChip('LOCATION: NOT REQUESTED', Icons.location_off_outlined),
    ]),
    const SizedBox(height: 11),
    _action('AUTO SCAN / CONNECT DIAGNOSTICS', Icons.bluetooth_searching, onGlasses,
      green: true),
    const SizedBox(height: 8),
    Text('App session $sessionDuration • Phone audio pairing ≠ camera BLE authentication',
      style: const TextStyle(fontSize: 10, color: _muted), textAlign: TextAlign.center),
  ]));

  Widget _glassCards(EbolaGlassStatus snapshot) => Row(children: [
    Expanded(child: _glass('V03 Pro', 'assets/images/g3.png',
      snapshot.candidate.toLowerCase().contains('v03') ? snapshot.connection : 'Not verified',
      snapshot.connected && snapshot.candidate.toLowerCase().contains('v03'))),
    const SizedBox(width: 8),
    Expanded(child: _glass('AIMB-G2 Pro', 'assets/images/g4.png', 'DZZ camera protocol unverified', false)),
  ]);

  Widget _glass(String title, String asset, String status, bool connected) => GestureDetector(
    onTap: onGlasses,
    child: _neonBox(padding: 10, child: Column(children: [
      SizedBox(height: 69, child: Image.asset(asset, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.visibility, color: _red, size: 54))),
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 14,
        fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text(status, maxLines: 2, textAlign: TextAlign.center,
        style: const TextStyle(color: _muted, fontSize: 10)),
      const SizedBox(height: 8),
      _Tag(connected ? 'CONNECTED' : 'NOT VERIFIED', green: connected),
    ])),
  );

  Widget _quickActions() => _neonBox(child: Column(children: [
    const Row(children: [Icon(Icons.flash_on, color: _green), SizedBox(width: 7),
      Text('CAMERA • VOICE • MEDIA', style: TextStyle(color: Colors.white,
        fontWeight: FontWeight.w900)), Spacer(), _Tag('HARDWARE TEST', green: false)]),
    const SizedBox(height: 12),
    LayoutBuilder(builder: (context, c) {
      final columns = c.maxWidth >= 520 ? 4 : 2;
      final tiles = <(String, IconData, VoidCallback)>[
        ('SCAN / CONNECT', Icons.bluetooth_connected, onGlasses),
        ('TAKE PHOTO', Icons.photo_camera, onGlasses),
        ('RECORD VIDEO', Icons.videocam, onGlasses),
        ('MEDIA IMPORT', Icons.cloud_download, onGlasses),
        ('VOICE COMMAND', Icons.mic, onGlasses),
        ('TALK TO EBOLA AI', Icons.record_voice_over, onMainchat),
        ('MY AI ACCOUNT', Icons.query_stats, () => onService('My AI Account')),
        ('SETTINGS', Icons.settings, () => onService('Settings')),
      ];
      return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns, mainAxisSpacing: 8, crossAxisSpacing: 8,
          childAspectRatio: columns == 2 ? 2.15 : 1.35),
        itemBuilder: (_, i) => _glassButton(tiles[i].$1, tiles[i].$2, tiles[i].$3));
    }),
    const SizedBox(height: 9),
    const Text('Capture → receive actual file → gallery → authenticated chat attachment. '
      'Automatic server upload remains disabled until the existing contract is verified.',
      style: TextStyle(color: _muted, fontSize: 10)),
  ]));

  Widget _qrPanel() => _neonBox(child: Row(children: [
    InkWell(onTap: onDashboard, child: Container(width: 104, height: 112,
      decoration: BoxDecoration(color: const Color(0xFF290D16),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: _green)),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.qr_code_scanner, color: _green, size: 56),
        Text('LIVE QR', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.bold)),
      ]))),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('EXISTING MEMBER QR', style: TextStyle(color: Colors.white,
        fontWeight: FontWeight.w900, fontSize: 13)),
      const SizedBox(height: 5),
      const Text('No replacement or synthetic QR. The server dashboard holds the original sponsor and payment identity.',
        style: TextStyle(color: _muted, fontSize: 11)),
      const SizedBox(height: 10),
      _action('OPEN LIVE QR', Icons.open_in_new, onDashboard),
    ])),
  ]));

  Widget _featureGrid(BuildContext context) {
    final features = <(String, IconData, VoidCallback)>[
      ('Home', Icons.home, onDashboard),
      ('My Glasses', Icons.visibility, onGlasses),
      ('Talk to EBOLA AI', Icons.mic, onMainchat),
      ('Students AI Teaching', Icons.school, () => onService('Students AI Teaching')),
      ('Blind Assist', Icons.accessibility_new, () => onService('Blind Assist')),
      ('Developer AI', Icons.code, () => onService('Developer AI')),
      ('Google Automation', Icons.trending_up, () => onService('Google Automation')),
      ('Facebook Automation', Icons.thumb_up, () => onService('Facebook Automation')),
      ('WhatsApp Automation', Icons.chat, () => onService('WhatsApp Automation')),
      ('6 Directors', Icons.account_tree, () => onService('6 Directors')),
      ('30 Managers', Icons.groups, () => onService('30 Managers')),
      ('Agentic AI', Icons.smart_toy, () => onService('Agentic AI')),
      ('Topstep Trading', Icons.candlestick_chart, () => onService('Topstep Trading')),
      ('EBOLA Hotel', Icons.hotel, () => onService('EBOLA Hotel')),
      ('EBOLA Restaurant', Icons.restaurant, () => onService('EBOLA Restaurant')),
      ('EBOLA Shop', Icons.shopping_cart, () => onService('EBOLA Shop')),
      ('EBOLA Home / Stay', Icons.house, () => onService('EBOLA Home / Stay')),
      ('Products List', Icons.inventory_2, () => onService('Products List')),
      ('Camera', Icons.camera_alt, onGlasses),
      ('Video Studio', Icons.movie, () => onService('Video Studio')),
      ('Translate', Icons.translate, () => onService('Translate')),
      ('Gallery', Icons.photo_library, () => onService('Gallery')),
      ('My AI Account', Icons.insights, () => onService('My AI Account')),
      ('AI Memory', Icons.lock, () => onService('AI Memory')),
      ('AI Agents', Icons.groups_2, () => onService('AI Agents')),
      ('Wallet', Icons.account_balance_wallet, () => onService('Wallet')),
      ('Nearby', Icons.place, () => onService('Nearby')),
      ('Referral / MLM', Icons.group_add, () => onService('Referral / MLM')),
      ('Firmware OTA', Icons.system_update, () => onService('Firmware OTA')),
      ('Support', Icons.support_agent, () => onService('Support')),
      ('Settings', Icons.settings, () => onService('Settings')),
    ];
    return LayoutBuilder(builder: (_, box) {
      final columns = box.maxWidth > 560 ? 5 : (box.maxWidth > 380 ? 4 : 3);
      return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: features.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns, mainAxisSpacing: 8, crossAxisSpacing: 8,
          childAspectRatio: .96),
        itemBuilder: (_, i) => _glassButton(features[i].$1, features[i].$2,
          features[i].$3, vertical: true));
    });
  }

  Widget _reliefPanel() => _neonBox(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Row(children: [Icon(Icons.medical_services, color: _green, size: 28),
      SizedBox(width: 9), Expanded(child: Text('EBOLA RELIEF 8.5 • 100 ml',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)))]),
    const SizedBox(height: 8),
    const Text('MRP ₹999 + applicable taxes. Seller availability, location, stock and account eligibility must be verified live.',
      style: TextStyle(color: _muted, fontSize: 11)),
    const SizedBox(height: 9),
    _action('FIND APPROVED HOLDER', Icons.location_searching,
      () => onService('EBOLA RELIEF Nearby Holder')),
  ]));

  Widget _services() => _neonBox(child: Column(children: [
    const Text('Flights • Hotels • Bus • Rail • Money Transfer • Recharge • Utility Bill • Shop',
      textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12)),
    const SizedBox(height: 10),
    _action('OPEN LIVE EBOLAPE WEBSITE', Icons.travel_explore,
      () => onService('EBOLAPE'), green: true),
  ]));

  Widget _heading(String text, String sub) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 9), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text, style: const TextStyle(color: Colors.white,
        fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: .6)),
      const SizedBox(height: 2),
      Text(sub, style: const TextStyle(color: _muted, fontSize: 10)),
    ]));

  Widget _glassButton(String label, IconData icon, VoidCallback onTap,
      {bool vertical = false}) => Material(color: const Color(0xFF230914),
    borderRadius: BorderRadius.circular(13), child: InkWell(onTap: onTap,
      borderRadius: BorderRadius.circular(13), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _red, width: 1.3),
        boxShadow: const [BoxShadow(color: Color(0x44FF153A), blurRadius: 9)]),
      child: vertical ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _red, size: 27), const SizedBox(height: 6),
        Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center, style: const TextStyle(color: Colors.white,
            fontSize: 10, fontWeight: FontWeight.w800)),
      ]) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _red, size: 25), const SizedBox(width: 8),
        Flexible(child: Text(label, maxLines: 2, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 11,
            fontWeight: FontWeight.w800))),
      ]))));

  Widget _action(String label, IconData icon, VoidCallback onTap, {bool green = false}) =>
    SizedBox(height: 42, child: FilledButton.icon(onPressed: onTap,
      style: FilledButton.styleFrom(backgroundColor: green ? const Color(0xFF116929) : const Color(0xFFAD0723),
        foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: green ? _green : _red))),
      icon: Icon(icon, size: 18), label: Text(label, maxLines: 1,
        overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800,
          fontSize: 10))));

  Widget _neonBox({required Widget child, bool green = false, double padding = 13}) =>
    Container(width: double.infinity, padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(19),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF320914), Color(0xFF0D0A0F)]),
        border: Border.all(color: green ? _green : _red, width: 1.5),
        boxShadow: [BoxShadow(color: green ? const Color(0x6639FF73) : const Color(0x66FF1739),
          blurRadius: 12, spreadRadius: 1)]), child: child);
}

class _Tag extends StatelessWidget {
  final String label;
  final bool green;
  const _Tag(this.label, {required this.green});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(9),
      color: green ? const Color(0xFF06361B) : const Color(0xFF45121C),
      border: Border.all(color: green ? _green : _red)),
    child: Text(label, style: TextStyle(color: green ? _green : const Color(0xFFFF8A9B),
      fontWeight: FontWeight.w900, fontSize: 9)));
}

class _StateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StateChip(this.label, this.icon);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
    decoration: BoxDecoration(color: const Color(0xFF20141B),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF793141))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _muted, size: 15), const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
    ]));
}
