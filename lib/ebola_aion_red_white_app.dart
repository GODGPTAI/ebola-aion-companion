// EBOLA AION / EBOLAPE — Red & White Companion Shell
// UI integration module. It does not claim OEM device connection or encryption.
// Device operations remain in the existing EbolaAionCameraProbe widget.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'ebola_aion_camera_probe.dart';

const Color _red = Color(0xFFB30813);
const Color _darkRed = Color(0xFF760009);
const Color _paper = Color(0xFFF8F8FA);
const Color _ink = Color(0xFF24272B);

void main() => runApp(const EbolaAionRedWhiteApp());

class EbolaAionRedWhiteApp extends StatelessWidget {
  const EbolaAionRedWhiteApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'EBOLA AION | EBOLAPE',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _paper,
      colorScheme: ColorScheme.fromSeed(seedColor: _red, primary: _red,
        surface: Colors.white),
      appBarTheme: const AppBarTheme(backgroundColor: _red,
        foregroundColor: Colors.white, elevation: 0),
    ),
    home: const _Shell(),
  );
}

class _Shell extends StatefulWidget {
  const _Shell();
  @override State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;
  final DateTime _started = DateTime.now();
  DateTime? _sessionEnded;
  Timer? _ticker;
  final List<String> _activity = [];
  bool _tracking = true;
  Duration get _duration => (_sessionEnded ?? DateTime.now()).difference(_started);
  @override void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _tracking && _tab == 0) setState(() {});
    });
    _event('App session started');
  }
  void _event(String message) {
    if (!mounted) return;
    setState(() {
      _activity.insert(0, '${DateTime.now().toLocal().toIso8601String().substring(11,19)}  $message');
      if (_activity.length > 35) _activity.removeLast();
    });
  }
  @override void dispose() { _ticker?.cancel(); super.dispose(); }
  String _fmt(Duration d) {
    final h=d.inHours.toString().padLeft(2,'0');
    final m=(d.inMinutes%60).toString().padLeft(2,'0');
    final s=(d.inSeconds%60).toString().padLeft(2,'0');
    return '$h:$m:$s';
  }
  void _openCamera() {
    _event('Opened native glasses camera controls');
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const EbolaAionCameraProbe()));
  }
  void _web(String title, String url) {
    _event('Opened $title');
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _WebPage(title: title, url: url)));
  }
  @override Widget build(BuildContext context) {
    final pages = [
      _devicePage(), _commercePage(), _studioPage(), _vaultPage(),
    ];
    return Scaffold(
      appBar: AppBar(toolbarHeight: 74, titleSpacing: 14,
        title: const Row(children: [
          _RoundBrand(), SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text('EBOLA AION', style: TextStyle(fontSize: 21,
              fontWeight: FontWeight.w900, letterSpacing: .4)),
              Text('SMART GLASSES • EBOLAPE', style: TextStyle(fontSize: 10,
                letterSpacing: 1.4))])),
        ]),
        actions: [IconButton(tooltip:'KRISHNA AI', onPressed: () => _web(
          'KRISHNA AI','https://www.ebolascan.online/krishna.php'),
          icon: const Icon(Icons.auto_awesome))],
      ),
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() => _tab=index);
          _event('Opened ${['Device','EBOLAPE','Studio','Vault'][index]} tab');
        },
        indicatorColor: const Color(0xFFFFD9DD),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.visibility_outlined),
            selectedIcon: Icon(Icons.visibility), label:'Device'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront), label:'EBOLAPE'),
          NavigationDestination(icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar), label:'3D Studio'),
          NavigationDestination(icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock), label:'Vault'),
        ],
      ),
    );
  }

  Widget _devicePage() => ListView(padding: const EdgeInsets.all(16),children: [
    const _SectionHeader(title:'DEVICE COMMAND CENTRE',
      subtitle:'V03 Pro • AIMB-G2 Pro • Camera & Voice', icon:Icons.visibility),
    _Panel(children: [
      const Row(children:[Icon(Icons.bluetooth_searching,color:_red),
        SizedBox(width:8), Expanded(child: Text('Your device connection status',
        style: TextStyle(fontWeight:FontWeight.bold,fontSize:16)))]),
      const SizedBox(height:12),
      _StateRow(Icons.sensors, 'Camera BLE',
        'Not verified in this dashboard — open hardware controls'),
      _StateRow(Icons.battery_unknown, 'Glasses battery',
        'Read from connected device; no estimated percentage'),
      _StateRow(Icons.camera_alt_outlined, 'Capture status',
        'Photo / video requires verified OEM camera connection'),
      const SizedBox(height:10),
      _PrimaryAction(label:'OPEN LIVE CAMERA & BLE CONTROLS',
        icon:Icons.bluetooth_connected, onTap:_openCamera),
      const SizedBox(height:6),
      const Text('Live Scan, Connect, Battery, Photo, Video and Voice are in '
        'the existing hardware test screen.',
        style:TextStyle(fontSize:12,color:Color(0xFF666666))),
    ]),
    const SizedBox(height:14),
    _Panel(children:[
      const _MiniTitle(Icons.grid_view_rounded, 'QUICK ACTIONS'),
      const SizedBox(height:10),
      _ActionGrid(items:[
        _Action('Detect Glass',Icons.bluetooth_searching,_openCamera),
        _Action('Connect',Icons.link,_openCamera),
        _Action('Take Photo',Icons.photo_camera,_openCamera),
        _Action('Start Video',Icons.videocam,_openCamera),
        _Action('Voice Command',Icons.mic,_openCamera),
        _Action('Download Media',Icons.download,_openCamera),
      ]),
      const SizedBox(height:8),
      const Text('All hardware actions open the existing real device probe; '
        'they do not claim successful capture.',
        style:TextStyle(fontSize:12,color:Color(0xFF666666))),
    ]),
    const SizedBox(height:14),
    _Panel(children:[
      const _MiniTitle(Icons.timer_outlined,'APP SESSION TIMER'),
      const SizedBox(height:10),
      Text(_fmt(_duration),style:const TextStyle(fontWeight:FontWeight.w900,
        fontSize:38,color:_darkRed,letterSpacing:2)),
      Text('Started: ${_started.toLocal().toString().substring(0,19)}',
        style:const TextStyle(fontSize:12)),
      Text(_tracking ? 'App session active' : 'Session ended',
        style: TextStyle(color:_tracking ? Colors.green[800] : Colors.grey[700])),
      if (_tracking) Align(alignment:Alignment.centerRight,
        child:TextButton.icon(onPressed:(){
          setState(() { _sessionEnded=DateTime.now();_tracking=false; });
          _event('App session ended');
        },icon:const Icon(Icons.stop_circle_outlined),label:const Text('End session'))),
      const Text('Tracks this app session only, not KRISHNA server processing '
        'or hardware camera recording time.',style:TextStyle(fontSize:11,
        color:Color(0xFF666666))),
    ]),
    const SizedBox(height:14),
    _Panel(children:[
      const _MiniTitle(Icons.list_alt,'APP ACTIVITY TIMELINE'),
      const SizedBox(height:8),
      for(final event in _activity.take(8)) Padding(
        padding:const EdgeInsets.symmetric(vertical:6),
        child:Row(children:[const Icon(Icons.circle,size:8,color:_red),
          const SizedBox(width:10),Expanded(child:Text(event,
            style:const TextStyle(fontSize:12)))])),
      const Text('Detailed BLE and capture logs are inside Hardware Controls.',
        style:TextStyle(fontSize:11,color:Color(0xFF777777))),
    ]),
  ]);

  Widget _commercePage() => ListView(padding:const EdgeInsets.all(16),children:[
    const _SectionHeader(title:'EBOLAPE.COM',
      subtitle:'Commerce • Travel • Payments • AI Services',icon:Icons.shopping_bag),
    _GradientHero(title:'ONE PLATFORM FOR EVERYDAY BUSINESS',
      subtitle:'Shop • Hotels • Travel • Recharge • Wallet • QR • AI',
      icon:Icons.storefront),
    const SizedBox(height:14),
    _Panel(children:[
      const _MiniTitle(Icons.apps, 'EBOLAPE SERVICES'),
      const SizedBox(height:8),
      _ActionGrid(items:[
        _Action('Shop',Icons.shopping_cart_outlined,()=>_web('EBOLAPE Shop','https://www.ebolape.com')),
        _Action('Hotel',Icons.hotel_outlined,()=>_web('EBOLAPE Hotels','https://www.ebolape.com')),
        _Action('Flights',Icons.flight_outlined,()=>_web('EBOLAPE Flights','https://www.ebolape.com/flight-booking')),
        _Action('Recharge',Icons.phone_android,()=>_web('EBOLAPE Recharge','https://www.ebolape.com')),
        _Action('QR',Icons.qr_code_2,()=>_web('EBOLAPE','https://www.ebolape.com')),
        _Action('Wallet',Icons.account_balance_wallet_outlined,()=>_web('EBOLAPE Wallet','https://www.ebolape.com')),
        _Action('KRISHNA AI',Icons.auto_awesome,()=>_web('KRISHNA AI','https://www.ebolascan.online/krishna.php')),
        _Action('Media',Icons.perm_media_outlined,()=>setState(()=>_tab=2)),
      ]),
      const SizedBox(height:8),
      const Text('Services open the website; transactions and login require '
        'their existing server implementation.',
        style:TextStyle(fontSize:12,color:Color(0xFF777777))),
    ]),
    const SizedBox(height:12),
    _PrimaryAction(label:'OPEN EBOLAPE.COM IN APP',icon:Icons.language,
      onTap:()=>_web('EBOLAPE','https://www.ebolape.com')),
  ]);

  Widget _studioPage() => ListView(padding:const EdgeInsets.all(16),children:[
    const _SectionHeader(title:'3D VIDEO & IMAGE STUDIO',
      subtitle:'Media gallery • AI tools • Render workspace', icon:Icons.view_in_ar),
    _GradientHero(title:'CREATE • RENDER • ORGANIZE',
      subtitle:'Use your existing EBOLA media services',icon:Icons.movie_creation_outlined),
    const SizedBox(height:14),
    _Panel(children:[
      const _MiniTitle(Icons.auto_fix_high, 'STUDIO TOOLS'),
      const SizedBox(height:10),
      _ActionGrid(items:[
        _Action('3D Workspace',Icons.view_in_ar,()=>_web('3D Workspace',
          'https://www.ebolascan.online/3dworkspace.php')),
        _Action('Video AI',Icons.movie_filter_outlined,()=>_web('Video AI Workforce',
          'https://www.ebolascan.online/videoaiworkforce.php')),
        _Action('AI Vision',Icons.document_scanner_outlined,()=>_web('KRISHNA Vision',
          'https://www.ebolascan.online/krishna.php')),
        _Action('Glass Capture',Icons.camera_alt_outlined,_openCamera),
      ]),
    ]),
    const SizedBox(height:14),
    _Panel(children:[
      const _MiniTitle(Icons.collections_outlined,'MEDIA GALLERY'),
      const SizedBox(height:8),
      Container(height:150,decoration:BoxDecoration(color:const Color(0xFFFFF4F4),
        borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFF3C5C5))),
        child:const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
          Icon(Icons.perm_media_outlined,color:_red,size:40),
          SizedBox(height:8), Text('No imported glass media yet',
            style:TextStyle(fontWeight:FontWeight.bold)),
          Text('Capture and import media first',style:TextStyle(fontSize:12)),
        ]))),
      const SizedBox(height:9),
      _PrimaryAction(label:'OPEN GLASS MEDIA IMPORT',icon:Icons.download,
        onTap:_openCamera),
    ]),
    const SizedBox(height:10),
    const Text('3D generation and media history depend on existing server '
      'endpoints; this UI does not invent completed renders.',
      style:TextStyle(color:Color(0xFF666666),fontSize:12)),
  ]);

  Widget _vaultPage() => ListView(padding:const EdgeInsets.all(16),children:[
    const _SectionHeader(title:'ENCRYPTED SECURE VAULT',
      subtitle:'Consent • Privacy • Media protection',icon:Icons.shield_outlined),
    _GradientHero(title:'YOUR DATA. YOUR CONTROL.',
      subtitle:'Authentication required before private media access',
      icon:Icons.lock_person_outlined),
    const SizedBox(height:14),
    _Panel(children:[
      const _MiniTitle(Icons.verified_user_outlined,'SECURITY STATUS'),
      const SizedBox(height:12),
      _StateRow(Icons.lock_outline,'Encrypted local glass files',
        'Not verified — no new unencrypted files saved by this UI'),
      _StateRow(Icons.cloud_off_outlined,'Automatic upload',
        'Disabled until authenticated server integration'),
      _StateRow(Icons.visibility_off_outlined,'Camera access',
        'Requires explicit consent inside Glass Camera Controls'),
      _StateRow(Icons.assignment_outlined,'Audit',
        'In-app session activity only'),
      const SizedBox(height:10),
      _PrimaryAction(label:'OPEN AUTHENTICATED KRISHNA',
        icon:Icons.shield_outlined,
        onTap:()=>_web('KRISHNA AI','https://www.ebolascan.online/krishna.php')),
    ]),
    const SizedBox(height:14),
    _Panel(children:[
      const _MiniTitle(Icons.collections_bookmark_outlined,'PROTECTED MEDIA GALLERY'),
      const SizedBox(height:12),
      const Center(child:Icon(Icons.lock_outline,color:_red,size:44)),
      const SizedBox(height:8),
      const Text('Gallery access is not enabled until the secure media API '
        'and account permissions are verified.',textAlign:TextAlign.center),
      const SizedBox(height:4),
    ]),
  ]);
}

class _WebPage extends StatefulWidget {
  final String title,url;
  const _WebPage({required this.title,required this.url});
  @override State<_WebPage> createState()=>_WebPageState();
}
class _WebPageState extends State<_WebPage> {
  late final WebViewController _controller;
  bool _loading=true;
  String? _error;
  @override void initState(){
    super.initState();
    _controller=WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted:(_){if(mounted)setState((){_loading=true;_error=null;});},
        onPageFinished:(_){if(mounted)setState(()=>_loading=false);},
        onWebResourceError:(e){if(e.isForMainFrame == true && mounted){
          setState((){_error=e.description;_loading=false;});
        }},
      ))
      ..loadRequest(Uri.parse(widget.url));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.title),actions:[
      IconButton(icon:const Icon(Icons.refresh),onPressed:()=>_controller.reload())]),
    body:Stack(children:[
      WebViewWidget(controller:_controller),
      if(_loading)const LinearProgressIndicator(color:_red),
      if(_error!=null)Center(child:Padding(padding:const EdgeInsets.all(20),
        child:Text('Website could not load: $_error'))),
    ]));
}

class _RoundBrand extends StatelessWidget{
  const _RoundBrand();
  @override Widget build(BuildContext context)=>Container(width:44,height:44,
    decoration:BoxDecoration(shape:BoxShape.circle,
      gradient:const LinearGradient(colors:[Colors.white,Color(0xFFFFC5C5)]),
      border:Border.all(color:Colors.white,width:2)),
    child:const Icon(Icons.auto_awesome,color:_red,size:27));
}
class _SectionHeader extends StatelessWidget{
  final String title,subtitle; final IconData icon;
  const _SectionHeader({required this.title,required this.subtitle,required this.icon});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:14,top:4),
    child:Row(children:[Container(padding:const EdgeInsets.all(11),
      decoration:BoxDecoration(color:const Color(0xFFFFE8E8),
        borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:_red)),
      const SizedBox(width:10), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
      children:[Text(title,style:const TextStyle(fontSize:17,
        fontWeight:FontWeight.w900,color:_darkRed)),
        Text(subtitle,style:const TextStyle(fontSize:12,color:Color(0xFF555555)))]))]));
}
class _Panel extends StatelessWidget{
  final List<Widget> children;
  const _Panel({required this.children});
  @override Widget build(BuildContext context)=>Container(width:double.infinity,
    padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),
      boxShadow:const [BoxShadow(color:Color(0x15000000),blurRadius:16,offset:Offset(0,6))],
      border:Border.all(color:const Color(0xFFF4E0E0))),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:children));
}
class _MiniTitle extends StatelessWidget{
  final IconData icon; final String title;
  const _MiniTitle(this.icon,this.title);
  @override Widget build(BuildContext context)=>Row(children:[Icon(icon,color:_red,size:22),
    const SizedBox(width:7),Flexible(child:Text(title,style:const TextStyle(fontSize:15,
      color:_darkRed,fontWeight:FontWeight.w900)))]);
}
class _StateRow extends StatelessWidget{
  final IconData icon; final String title,value;
  const _StateRow(this.icon,this.title,this.value);
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Icon(icon,size:20,color:_red),const SizedBox(width:9),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:13)),
        Text(value,style:const TextStyle(color:Color(0xFF6A6A6A),fontSize:12))]))]));
}
class _PrimaryAction extends StatelessWidget{
  final String label;final IconData icon;final VoidCallback onTap;
  const _PrimaryAction({required this.label,required this.icon,required this.onTap});
  @override Widget build(BuildContext context)=>SizedBox(width:double.infinity,height:49,
    child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:_red,
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(13))),
      onPressed:onTap,icon:Icon(icon),label:Text(label,style:const TextStyle(
        fontSize:12,fontWeight:FontWeight.w800))));
}
class _Action{
  final String title;final IconData icon;final VoidCallback onTap;
  const _Action(this.title,this.icon,this.onTap);
}
class _ActionGrid extends StatelessWidget{
  final List<_Action> items;
  const _ActionGrid({required this.items});
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,constraints){
    final n=constraints.maxWidth>=560?4:3;
    return GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
      itemCount:items.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:n,crossAxisSpacing:9,mainAxisSpacing:9,childAspectRatio:1.05),
      itemBuilder:(context,i){final e=items[i];return OutlinedButton(
        style:OutlinedButton.styleFrom(padding:const EdgeInsets.all(4),
          backgroundColor:i%4==0?const Color(0xFFFFF0F0):Colors.white,
          side:const BorderSide(color:Color(0xFFF0B6B6)),
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(13))),
        onPressed:e.onTap,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(e.icon,color:_red,size:27),const SizedBox(height:6),
          Text(e.title,textAlign:TextAlign.center,
            style:const TextStyle(color:_ink,fontSize:11,fontWeight:FontWeight.w800))]));});
  });
}
class _GradientHero extends StatelessWidget{
  final String title,subtitle;final IconData icon;
  const _GradientHero({required this.title,required this.subtitle,required this.icon});
  @override Widget build(BuildContext context)=>Container(
    width:double.infinity,padding:const EdgeInsets.all(22),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),
      gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
        colors:[_darkRed,_red,Color(0xFFEA343D)])),
    child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
      children:[Text(title,style:const TextStyle(color:Colors.white,
        fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:8),
        Text(subtitle,style:const TextStyle(color:Color(0xFFFFE8E8),fontSize:13))])),
      const SizedBox(width:8),Icon(icon,size:70,color:Colors.white70)]));
}
