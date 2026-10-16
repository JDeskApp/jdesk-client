// J Desk: tela simplificada do cliente.
// Aparece quando o app foi aberto a partir do arquivo baixado no painel
// (jdesk-CODIGO.exe). Mostra o ID, o técnico e a instrução de clicar em Aceitar.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:http/http.dart' as http;

const kJDeskVerde = Color(0xFF0B7A75);
const kJDeskVerdeEscuro = Color(0xFF0A3B38);
const kJDeskVerdeMeio = Color(0xFF0B5E5A);
const kJDeskTexto = Color(0xFF0F1B2D);
const kJDeskTexto2 = Color(0xFF536170);
const kJDeskFundo = Color(0xFFF1F8F6);
const kJDeskBorda = Color(0xFFD9E7E3);
const kJDeskStatus = Color(0xFF15803D);

/// Código do chamado (ex.: 4F7K) quando o app veio do painel; vazio no app do técnico.
String jdeskCodigo() => bind.mainGetBuildinOption(key: 'jdesk-codigo');

bool isJDeskClientMode() => bind.isIncomingOnly() && jdeskCodigo().isNotEmpty;

class JDeskClientPane extends StatefulWidget {
  final Key contentKey;
  final VoidCallback onResize;

  const JDeskClientPane(
      {Key? key, required this.contentKey, required this.onResize})
      : super(key: key);

  @override
  State<JDeskClientPane> createState() => _JDeskClientPaneState();
}

class _JDeskClientPaneState extends State<JDeskClientPane> {
  String _empresa = '';
  String _tecnico = '';
  String _contato = '';
  String _telefone = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregar();
    // Os dados do chamado podem mudar (ex.: troca de técnico); atualiza de tempos em tempos.
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _carregar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    final codigo = jdeskCodigo();
    final painel = bind.mainGetBuildinOption(key: 'jdesk-painel');
    if (codigo.isEmpty || painel.isEmpty) return;
    try {
      final resp = await http
          .get(Uri.parse('$painel/api/chamado/$codigo'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return;
      final dados = jsonDecode(utf8.decode(resp.bodyBytes));
      if (dados is! Map) return;
      if (!mounted) return;
      setState(() {
        _empresa = (dados['empresa'] ?? '').toString();
        _tecnico = (dados['tecnico'] ?? '').toString();
        _contato = (dados['contato'] ?? '').toString();
        _telefone = (dados['telefone'] ?? '').toString();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onResize());
    } catch (e) {
      debugPrint('J Desk: dados do chamado indisponiveis: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final corCartao = escuro ? const Color(0xFF132B29) : Colors.white;
    final corTexto = escuro ? Colors.white : kJDeskTexto;
    final corTexto2 = escuro ? const Color(0xFFA9C9C5) : kJDeskTexto2;
    final corBorda = escuro ? const Color(0xFF23403E) : kJDeskBorda;
    final nome = _contato.trim();
    final codigo = jdeskCodigo();

    final cabecalho = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kJDeskVerdeEscuro, kJDeskVerdeMeio, kJDeskVerde],
        ),
      ),
      child: Column(
        children: [
          SvgPicture.asset('assets/icon.svg', width: 60, height: 60),
          const SizedBox(height: 10),
          Text(
            _empresa.isEmpty
                ? 'SUPORTE REMOTO'
                : 'SUPORTE REMOTO · ${_empresa.toUpperCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFA9D8D1),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            nome.isEmpty ? 'Tudo pronto!' : 'Tudo pronto, $nome!',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _tecnico.isEmpty
                ? 'O técnico já foi avisado e vai se conectar em instantes.'
                : 'O técnico $_tecnico já foi avisado e vai se conectar em instantes.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFD3ECE8), fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );

    final cartao = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: corCartao,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: corBorda),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A0A3B38), blurRadius: 24, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: escuro ? const Color(0xFF11351F) : const Color(0xFFE3F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: kJDeskStatus, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pronto · aguardando o técnico',
                    style: TextStyle(
                        color: escuro
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFF14532D),
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('SEU ID J DESK',
              style: TextStyle(
                  color: corTexto2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0)),
          const SizedBox(height: 4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: gFFI.serverModel.serverId,
            builder: (context, value, child) => SelectableText(
              value.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: 1.5,
                  color: corTexto),
            ),
          ),
          const SizedBox(height: 4),
          Text('Só passe este número se o técnico pedir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: corTexto2, fontSize: 12)),
          const SizedBox(height: 14),
          Divider(height: 1, color: corBorda),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 22,
                  color: escuro ? const Color(0xFF5CC5BC) : kJDeskVerde),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Quando aparecer o aviso, clique em Aceitar. Para encerrar o acesso a qualquer momento, é só fechar o J Desk.',
                  style: TextStyle(
                      color: escuro
                          ? const Color(0xFFCFE3DF)
                          : const Color(0xFF334155),
                      fontSize: 13,
                      height: 1.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final rodape = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Text('Atendimento ',
              style: TextStyle(color: corTexto2, fontSize: 12)),
          Text(codigo,
              style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: corTexto)),
          const Spacer(),
          if (_telefone.isNotEmpty)
            Flexible(
              child: Text('Precisa de ajuda? $_telefone',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: corTexto2, fontSize: 12)),
            ),
        ],
      ),
    );

    return Container(
      width: 380,
      color: escuro ? const Color(0xFF0C1F1E) : kJDeskFundo,
      child: SingleChildScrollView(
        child: Column(
          key: widget.contentKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            cabecalho,
            // O cartão sobe sobre o cabeçalho, como na proposta aprovada.
            Transform.translate(offset: const Offset(0, -36), child: cartao),
            Transform.translate(offset: const Offset(0, -24), child: rodape),
            Transform.translate(
              offset: const Offset(0, -20),
              child: OnlineStatusWidget(onSvcStatusChanged: widget.onResize),
            ),
          ],
        ),
      ),
    );
  }
}
