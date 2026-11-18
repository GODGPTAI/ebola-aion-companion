// EBOLA AION — red/white HOME V2, visual shell only.
// Camera/BLE lives in existing hardware probe. QR is original-asset-only.
import 'package:flutter/material.dart';

const _red = Color(0xFFC60009);
const _redDark = Color(0xFF78000A);
const _line = Color(0xFFF3BFC2);
const _soft = Color(0xFFFFF2F2);

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
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
    children: [
      _hero(),
      const SizedBox(height: 10),
      _glassStatus(),
      const SizedBox(height: 10),
      _section('ONE QR. ALL POWER.', 'Existing original QR • Same sponsor'),
      _qrHub(),
      const SizedBox(height: 12),
      _section('CAMERA • MEDIA', 'Hardware-connected capture and gallery'),
      _captureCard(),
      const SizedBox(height: 12),
      _section('YOUR AI COMPANY OS', 'Every section opens its own screen or service'),
      _tileGrid(context),
      const SizedBox(height: 12),
      _section('EBOLA RELIEF 8.5', 'Find an authorized holder near you'),
      _reliefCard(),
      const SizedBox(height: 12),
      _section('EBOLAPE SERVICES', 'Existing live website • No duplicate fake icons'),
      _services(),
      const SizedBox(height: 12),
      _footer(context),
    ],
  );

  Widget _hero() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(colors: [_redDark, _red, Color(0xFFF7363B)])),
    child: Row(children: [
      ClipOval(child: Image.asset('assets/ebola_home_brand.png', width: 68,
        height: 68, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome,
          color: Colors.white, size: 48))),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('EBOLA AI', style: TextStyle(color: Colors.white,
          fontSize: 28, fontWeight: FontWeight.w900)),
          Text('AGENTIC AI COMPANY OS', style: TextStyle(color: Colors.white,
            fontSize: 10, letterSpacing: 1.1)),
          SizedBox(height: 4),
          Text('Glasses • Voice • Business • ONE QR', style:
            TextStyle(color: Colors.white, fontSize: 11))])),
    ]),
  );

  Widget _glassStatus() => _card(children: [
    Row(children: [
      const Icon(Icons.visibility, color: _red, size: 30),
      const SizedBox(width: 8),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('MY SMART GLASSES', style: TextStyle(fontWeight:
          FontWeight.w900, color: _redDark, fontSize: 15)),
          Text('V03 Pro / AIMB-G2 Pro • Select inside controls',
            style: TextStyle(fontSize: 11))])),
      _batteryUnknown(),
    ]),
    const SizedBox(height: 10),
    const Row(children: [Icon(Icons.circle_outlined, color: Colors.orange, size: 14),
      SizedBox(width: 6), Expanded(child: Text('Camera BLE: Not verified — tap Connect to test',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)))]),
    const SizedBox(height: 7),
    Text('App session: $sessionDuration  •  Glass recording timer is separate',
      style: const TextStyle(fontSize: 11, color: _redDark)),
    const SizedBox(height: 10),
    _solid('DETECT / CONNECT GLASSES', Icons.bluetooth_searching, onGlasses),
  ]);

  Widget _batteryUnknown() => Container(width: 62, height: 62,
    decoration: const BoxDecoration(shape: BoxShape.circle,
      gradient: SweepGradient(colors: [Color(0xFFD4D4D4), Color(0xFFF6F6F6),
        Color(0xFFD4D4D4)])),
    child: Center(child: Container(width: 49, height: 49,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.battery_unknown, color: _red, size: 17),
        Text('--%', style: TextStyle(fontSize: 16, color: _redDark,
          fontWeight: FontWeight.w900))]))));

  Widget _qrHub() => _card(children: [
    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: _qrTile()),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _smallPill('Referral / Signup', Icons.group_add),
          _smallPill('WhatsApp Business', Icons.chat),
          _smallPill('Google Business', Icons.storefront),
          _smallPill('Products / Payments', Icons.shopping_cart),
        ])),
    ]),
    const SizedBox(height: 8),
    const Text('Use your approved ONE QR image only. Sponsor placement and payment QR are unchanged.',
      style: TextStyle(fontSize: 10, color: Color(0xFF555555))),
  ]);

  Widget _qrTile() => Container(height: 178,
    decoration: BoxDecoration(border: Border.all(color: _red, width: 2),
      color: _soft, borderRadius: BorderRadius.circular(18)),
    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.qr_code_2, color: _redDark, size: 70),
      SizedBox(height: 7),
      Text('ORIGINAL QR', style: TextStyle(color: _redDark,
        fontWeight: FontWeight.w900, fontSize: 12)),
      Padding(padding: EdgeInsets.all(5), child: Text('Image not configured',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 10))),
    ]));

  Widget _smallPill(String t, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 7,vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _line), color: Colors.white),
      child: Row(children: [Icon(icon,color:_red,size:18),const SizedBox(width:5),
        Expanded(child: Text(t,style: const TextStyle(fontSize: 10,
          fontWeight: FontWeight.w800)))])));

  Widget _captureCard() => _card(children: [
    const Row(children: [Icon(Icons.photo_camera, color: _red),
      SizedBox(width: 7), Expanded(child: Text('Glass Photo • Video • Audio',
        style: TextStyle(color: _redDark, fontWeight: FontWeight.w900)))]),
    const SizedBox(height: 9),
    Row(children: [
      Expanded(child: _outline('PHOTO', Icons.camera_alt, onGlasses)),
      const SizedBox(width: 6),
      Expanded(child: _outline('VIDEO', Icons.videocam, onGlasses)),
      const SizedBox(width: 6),
      Expanded(child: _outline('VOICE', Icons.mic, onGlasses)),
    ]),
    const SizedBox(height: 10),
    const Wrap(spacing: 6, runSpacing: 6, children: [
      _MediaStep('01 Capture', Icons.camera),
      _MediaStep('02 Import', Icons.download),
      _MediaStep('03 Gallery', Icons.photo_library),
      _MediaStep('04 Attach', Icons.attach_file),
      _MediaStep('05 EBOLA AI', Icons.smart_toy),
    ]),
    const SizedBox(height: 9),
    const Text('Auto-send requires a verified glass file and an authenticated /mainchatbar.php uploader. Not active yet.',
      style: TextStyle(fontSize: 10, color: Color(0xFF656565))),
    const SizedBox(height: 8),
    _solid('OPEN EBOLA AI MAIN CHATBAR', Icons.chat_bubble, onMainchat),
  ]);

  Widget _tileGrid(BuildContext context) {
    final items = <_TileInfo>[
      _TileInfo('Home', Icons.home, onDashboard),
      _TileInfo('My Glasses', Icons.visibility, onGlasses),
      _TileInfo('Talk to EBOLA AI', Icons.mic, onMainchat),
      _TileInfo('Students AI', Icons.school, () => onService('Students AI Teaching')),
      _TileInfo('Blind Assist', Icons.accessibility_new, () => onService('Blind Assist')),
      _TileInfo('Developer AI', Icons.code, () => onService('Developer AI')),
      _TileInfo('Google Automation', Icons.trending_up, () => onService('Google Automation')),
      _TileInfo('Facebook Automation', Icons.thumb_up, () => onService('Facebook Automation')),
      _TileInfo('WhatsApp Automation', Icons.chat, () => onService('WhatsApp Automation')),
      _TileInfo('6 Directors', Icons.account_tree, () => onService('6 Directors')),
      _TileInfo('30 Managers', Icons.groups, () => onService('30 Managers')),
      _TileInfo('Agentic AI', Icons.smart_toy, () => onService('Agentic AI')),
      _TileInfo('Topstep Trading', Icons.candlestick_chart, () => onService('Topstep Trading')),
      _TileInfo('EBOLA Hotel', Icons.hotel, () => onService('EBOLA Hotel')),
      _TileInfo('Restaurant', Icons.restaurant, () => onService('EBOLA Restaurant')),
      _TileInfo('EBOLA Shop', Icons.shopping_cart, () => onService('EBOLA Shop')),
      _TileInfo('Home / Stay', Icons.house, () => onService('EBOLA Home / Stay')),
      _TileInfo('Products List', Icons.inventory, () => onService('Products List')),
      _TileInfo('Camera', Icons.photo_camera, onGlasses),
      _TileInfo('Video Studio', Icons.movie, () => onService('Video Studio')),
      _TileInfo('Translate', Icons.translate, () => onService('Translate')),
      _TileInfo('Gallery', Icons.photo_library, () => onService('Gallery')),
      _TileInfo('My AI Account', Icons.insights, () => onService('My AI Account')), // EBOLA_MY_AI_ACCOUNT_V1
      _TileInfo('AI Memory', Icons.lock, () => onService('AI Memory')),
      _TileInfo('AI Agents', Icons.groups_2, () => onService('AI Agents')),
      _TileInfo('Wallet', Icons.account_balance_wallet, () => onService('Wallet')),
      _TileInfo('Nearby', Icons.place, () => onService('Nearby')),
      _TileInfo('Referral / MLM', Icons.group_add, () => onService('Referral / MLM')),
      _TileInfo('Firmware OTA', Icons.system_update, () => onService('Firmware OTA')),
      _TileInfo('Support', Icons.support_agent, () => onService('Support')),
      _TileInfo('Settings', Icons.settings, () => onService('Settings')),
    ];
    return LayoutBuilder(builder: (context, c) {
      final n = c.maxWidth > 700 ? 6 : (c.maxWidth > 440 ? 4 : 3);
      return GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: n, crossAxisSpacing: 7, mainAxisSpacing: 7,
          childAspectRatio: 0.94),
        itemBuilder: (_, i) {
          final e = items[i];
          return Material(color: Colors.white, borderRadius: BorderRadius.circular(13),
            child: InkWell(onTap: e.tap, borderRadius: BorderRadius.circular(13),
              child: Container(padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _red, width: 1.25)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(e.icon, color: _red, size: 28),
                    const SizedBox(height: 5), Text(e.label,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center, style: const TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w800,
                        fontSize: 10))]))));
        });
    });
  }

  Widget _reliefCard() => _card(children: [
    const Row(children: [Icon(Icons.medical_services, size: 34, color: _red),
      SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('EBOLA RELIEF 8.5 • 100 ml',
          style: TextStyle(fontSize: 16,color: _redDark,fontWeight: FontWeight.w900)),
          Text('MRP ₹999 + applicable tax • Authorized sellers',
            style: TextStyle(fontSize: 11))]))]),
    const SizedBox(height: 9),
    const Text('Customer: locate approved holder by State, District and PIN. Stock, phone, user_code and route must come from live records.',
      style: TextStyle(fontSize: 11)),
    const SizedBox(height: 9),
    _solid('FIND HOLDER / BUY SPRAY', Icons.place,
      () => onService('EBOLA RELIEF Nearby Holder')),
    const SizedBox(height: 7),
    const Text('Company holder order: ₹700 + 5% GST = ₹735/bottle • minimum 5. Eligibility and stock require server verification.',
      style: TextStyle(fontSize: 10,color: Color(0xFF666666))),
  ]);

  Widget _services() => _card(children: [
    Wrap(spacing: 7, runSpacing: 7, children: [
      for(final s in <(String, IconData)>[
        ('Flight', Icons.flight), ('Hotel', Icons.hotel),
        ('Bus', Icons.directions_bus), ('Rail', Icons.train),
        ('Recharge', Icons.phone_android), ('Money Transfer', Icons.currency_rupee),
        ('Utility Bill', Icons.receipt_long), ('Shop', Icons.shopping_cart),
      ]) ActionChip(avatar: Icon(s.$2, color: _red, size: 17),
        label: Text(s.$1, style: const TextStyle(fontSize: 11)),
        onPressed: () => onService('EBOLAPE ${s.$1}')),
    ]),
    const SizedBox(height: 7),
    const Text('EBOLAPE services open existing live site; individual services are not re-created here.',
      style: TextStyle(fontSize: 10,color: Color(0xFF666666))),
  ]);

  Widget _footer(BuildContext context) => Row(children: [
    Expanded(child: _outline('EBOLAPE.COM', Icons.language,
      () => onService('EBOLAPE'))),
    const SizedBox(width: 7),
    Expanded(child: _outline('DASHBOARD', Icons.dashboard, onDashboard)),
  ]);

  Widget _section(String title, String sub) => Padding(
    padding: const EdgeInsets.fromLTRB(3, 8, 3, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900,
        color: _redDark, fontSize: 16)),
      Text(sub, style: const TextStyle(fontSize: 10,color: Color(0xFF666666))),
    ]));

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(19),
      boxShadow: const [BoxShadow(blurRadius: 9,color: Color(0x11000000),
        offset: Offset(0,3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,children: children));

  Widget _solid(String text, IconData icon, VoidCallback tap) =>
    SizedBox(height: 43, child: FilledButton.icon(onPressed: tap,
      style: FilledButton.styleFrom(backgroundColor: _red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      icon: Icon(icon, size: 19), label: Text(text,
        style: const TextStyle(fontSize: 11,fontWeight: FontWeight.w900))));

  Widget _outline(String text, IconData icon, VoidCallback tap) =>
    SizedBox(height: 52,child: OutlinedButton(onPressed: tap,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(4),
        side: const BorderSide(color: _line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _red, size: 20),
        Text(text,style: const TextStyle(fontSize: 9,fontWeight: FontWeight.w900,
          color: _redDark))])));
}

class _MediaStep extends StatelessWidget {
  final String title; final IconData icon;
  const _MediaStep(this.title,this.icon);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7,vertical: 6),
    decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _line)),
    child: Row(mainAxisSize: MainAxisSize.min,children: [
      Icon(icon, size: 14,color: _red), const SizedBox(width: 4),
      Text(title, style: const TextStyle(fontSize: 10,fontWeight: FontWeight.w800))]));
}
class _TileInfo {
  final String label; final IconData icon; final VoidCallback tap;
  const _TileInfo(this.label,this.icon,this.tap);
}
