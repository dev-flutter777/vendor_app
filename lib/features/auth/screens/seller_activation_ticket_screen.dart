import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';

class SellerActivationTicketScreen extends StatefulWidget {
  const SellerActivationTicketScreen({super.key});
  @override
  State<SellerActivationTicketScreen> createState() => _SellerActivationTicketScreenState();
}

class _SellerActivationTicketScreenState extends State<SellerActivationTicketScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> _messages = [];
  int? _ticketId;
  Timer? _poller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _poller = Timer.periodic(const Duration(seconds: 20), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final auth = Provider.of<AuthController>(context, listen: false);
    await auth.openActivationTicket();
    final response = await auth.activationTicketMessages(ticketId: _ticketId);
    if (!mounted) return;
    if (response.response?.statusCode == 200 && response.response?.data is Map) {
      final data = response.response!.data as Map;
      _ticketId = data['activation_ticket']?['id'] as int?;
      setState(() {
        _messages = List<dynamic>.from(data['messages'] ?? []);
        _loading = false;
      });
      await auth.loadActivationStatus();
      if (auth.activation?['status'] == 'active' && mounted) Navigator.pop(context);
    } else if (!silent) {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;
    final response = await Provider.of<AuthController>(context, listen: false).sendActivationTicketMessage(body, ticketId: _ticketId);
    if (response.response?.statusCode == 201) {
      _messageController.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getTranslated('activation_support', context) ?? '')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: _messages.length, itemBuilder: (_, index) {
          final message = _messages[index] as Map;
          final mine = message['sender_type'] == 'seller';
          final isRtl = Directionality.of(context) == TextDirection.rtl;
          return Align(alignment: mine ? (isRtl ? Alignment.centerLeft : Alignment.centerRight) : (isRtl ? Alignment.centerRight : Alignment.centerLeft), child: Card(color: mine ? Theme.of(context).primaryColor.withValues(alpha: .12) : null, child: Padding(padding: const EdgeInsets.all(10), child: Text("${message['body'] ?? ''}"))));
        })),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: _messageController, minLines: 1, maxLines: 4, decoration: InputDecoration(border: const OutlineInputBorder(), hintText: getTranslated('write_activation_message', context)))),
          IconButton(onPressed: _send, icon: const Icon(Icons.send)),
        ]))),
      ]),
    );
  }
}
