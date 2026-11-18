// EBOLA AION My AI Account - EXACT 31 sidebar tabs from supplied my_ai_account.php.
// Reuses logged-in PHP page and its live server-side ledger/graphs.
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class _AiTab {
  final String key, title;
  const _AiTab(this.key,this.title);
}

class EbolaMyAiAccountScreen extends StatefulWidget {
  const EbolaMyAiAccountScreen({super.key});
  @override
  State<EbolaMyAiAccountScreen> createState() => _EbolaMyAiAccountScreenState();
}

class _EbolaMyAiAccountScreenState extends State<EbolaMyAiAccountScreen> {
  static const Color red = Color(0xFFC60009);
  static const String endpoint = 'https://www.ebolascan.online/ai/my_ai_account.php';
  static const List<_AiTab> tabs = [
    _AiTab('usage', 'Usage Overview'),
    _AiTab('trading', 'Topstep / Trading AI'),
    _AiTab('chat', 'Chat AI'),
    _AiTab('audio', 'Audio / Voice AI'),
    _AiTab('images', 'Image AI'),
    _AiTab('video', 'Video AI'),
    _AiTab('3d', '3D Studio'),
    _AiTab('avatar', 'Avatar Studio'),
    _AiTab('codex', 'CODIAX / Coding AI'),
    _AiTab('research', 'Research AI'),
    _AiTab('website', 'Website / App AI'),
    _AiTab('documents', 'Documents / OCR AI'),
    _AiTab('pdf', 'PDF AI'),
    _AiTab('presentation', 'Presentation AI'),
    _AiTab('spreadsheet', 'Spreadsheet AI'),
    _AiTab('workflow', 'Workflow AI'),
    _AiTab('automation', 'Automation AI'),
    _AiTab('api', 'API / Tools AI'),
    _AiTab('database', 'Database / SQL AI'),
    _AiTab('agents', 'All Agents'),
    _AiTab('commerceoverview', 'Commerce OS · All 48'),
    _AiTab('business', 'Business & Categories'),
    _AiTab('google', 'Google Ranking & SEO'),
    _AiTab('whatsappcommerce', 'WhatsApp Commerce'),
    _AiTab('qr', 'Universal QR & Storefront'),
    _AiTab('crm', 'CRM & Follow-up'),
    _AiTab('orders', 'Orders & Payments'),
    _AiTab('campaign', 'Marketing & Reviews'),
    _AiTab('operations', 'Security & Recovery'),
    _AiTab('business_os', 'Business OS · 6 Directors / 30 Managers'),
    _AiTab('departments', 'Departments')
  ];
  late final WebViewController _web;
  String _selected='usage';
  int _days=7;
  bool _loading=true;
  bool _failed=false;
  @override void initState(){
    super.initState();
    _web=WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_){if(mounted)setState((){_loading=true;_failed=false;});},
        onPageFinished: (_){if(mounted)setState((){_loading=false;});},
        onWebResourceError: (e){if(e.isForMainFrame==true && mounted)setState((){_loading=false;_failed=true;});},
      ));
    _load();
  }
  Uri get _target => Uri.parse('$endpoint?tab=${Uri.encodeQueryComponent(_selected)}&days=$_days&embed=dashboard');
  void _load(){_web.loadRequest(_target);}
  void _choose(String key){
    if(key==_selected){Navigator.of(context).maybePop();return;}
    setState((){_selected=key;});
    _load();
  }
  String get _title => tabs.firstWhere((t)=>t.key==_selected).title;
  Widget _menu({bool permanent=false})=>Container(
    width:permanent?262:300,color:Colors.white,
    child:SafeArea(child:Column(children:[
      Container(width:double.infinity,padding:const EdgeInsets.all(16),color:red,
        child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('EBOLA AI',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),
          SizedBox(height:3),Text('MY AI ACCOUNT · ALL 31 SECTIONS',style:TextStyle(color:Colors.white,fontSize:11))
        ])),
      Expanded(child:ListView.builder(itemCount:tabs.length,itemBuilder:(context,index){
        final tab=tabs[index];final active=tab.key==_selected;
        return ListTile(dense:true,selected:active,selectedTileColor:const Color(0xFFFFE4E5),
          leading:CircleAvatar(radius:14,backgroundColor:active?red:const Color(0xFFFFF0F0),
            child:Text('${index+1}',style:TextStyle(color:active?Colors.white:red,fontSize:11,fontWeight:FontWeight.bold))),
          title:Text(tab.title,style:TextStyle(fontSize:13,fontWeight:active?FontWeight.w800:FontWeight.w500)),
          trailing:active?const Icon(Icons.chevron_right,color:red,size:18):null,
          onTap:(){if(!permanent)Navigator.pop(context);setState(()=>_selected=tab.key);_load();});
      })),
      const Padding(padding:EdgeInsets.all(12),child:Text('LIVE DATABASE · NO DEMO COUNTS',style:TextStyle(fontSize:10,color:Colors.black54)))
    ])));
  Widget _main()=>Column(children:[
    Container(color:const Color(0xFFFFF1F1),padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:Row(children:[
      const Icon(Icons.analytics_outlined,color:red),const SizedBox(width:7),
      Expanded(child:Text(_title,maxLines:2,overflow:TextOverflow.ellipsis,
        style:const TextStyle(fontWeight:FontWeight.bold,fontSize:14))),
      DropdownButton<int>(value:_days,isDense:true,underline:const SizedBox.shrink(),items:const [
        DropdownMenuItem(value:1,child:Text('1d')),DropdownMenuItem(value:7,child:Text('7d')),
        DropdownMenuItem(value:30,child:Text('30d')),DropdownMenuItem(value:90,child:Text('90d')),
        DropdownMenuItem(value:365,child:Text('1y')),DropdownMenuItem(value:0,child:Text('All')),
      ],onChanged:(v){if(v!=null){setState(()=>_days=v);_load();}})
    ])),
    if(_loading)const LinearProgressIndicator(minHeight:3,color:red),
    if(_failed)const Padding(padding:EdgeInsets.all(10),child:Text('Account data unavailable. Check network and login session.',style:TextStyle(color:red))),
    Expanded(child:WebViewWidget(controller:_web)),
    const Padding(padding:EdgeInsets.symmetric(horizontal:8,vertical:5),child:Text(
      'Input / output / usage / cost are from recorded server events only.',
      textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:Colors.black54))),
  ]);
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,c){
    final wide=c.maxWidth>=850;
    return Scaffold(
      appBar:AppBar(backgroundColor:red,foregroundColor:Colors.white,
        title:const Text('MY AI ACCOUNT',style:TextStyle(fontWeight:FontWeight.w900)),
        actions:[IconButton(tooltip:'Refresh live account',onPressed:_load,icon:const Icon(Icons.refresh))]),
      drawer:wide?null:Drawer(child:_menu()),
      body:SafeArea(child:Row(children:[
        if(wide)_menu(permanent:true),
        Expanded(child:_main()),
      ])),
    );
  });
}
