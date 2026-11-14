import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../app_imports.dart';
import '../services/ai_assistant_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isLoading = false;

  final List _messages = [
    {
      'sender': 'ai',
      'text':
          'أهلاً بك يا كابتن عبد الجواد. أنا مساعدك الذكي العقاري الشامل.\nاضغط على زر الميكروفون وتكلم بصوتك أو استخدم الآلة الحاسبة المتكاملة بالأعلى.'
    }
  ];

  final List _quickPrompts = [
    'ملخص شامل للمنظومة',
    'الشقق المعروضة للبيع',
    'طلبات العملاء الحالية',
    'تقرير الحسابات والمالية',
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {}
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_messageController.text.trim().isNotEmpty) {
        _sendMessage();
      }
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
    }

    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الميكروفون غير متاح أو لم يتم منح صلاحية الصوت على هذا الجهاز.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    String chosenLocale = 'ar_EG';
    try {
      var locales = await _speech.locales();
      var arLocale = locales.where((l) => l.localeId.toLowerCase().startsWith('ar')).toList();
      if (arLocale.isNotEmpty) {
        chosenLocale = arLocale.first.localeId;
      }
    } catch (_) {}

    setState(() => _isListening = true);

    await _speech.listen(
      localeId: chosenLocale,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
      ),
      onResult: (result) {
        if (mounted) {
          setState(() {
            _messageController.text = result.recognizedWords;
          });
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            setState(() => _isListening = false);
            _sendMessage();
          }
        }
      },
    );
  }

  void _sendMessage([String? customText]) async {
    String text = (customText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    String aiResponse = await AiAssistantService.sendMessageToAI(text);
    aiResponse = aiResponse.replaceAll('**', '');

    if (mounted) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': aiResponse});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // آلة حاسبة متكاملة منبثقة
  void _showIntegratedCalculator() {
    String display = '0';
    double firstNum = 0;
    String operator = '';
    bool shouldReset = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setCalcState) {
          void onPress(String val) {
            setCalcState(() {
              if (val == 'C') {
                display = '0';
                firstNum = 0;
                operator = '';
                shouldReset = false;
              } else if (val == '⌫') {
                if (display.length > 1) {
                  display = display.substring(0, display.length - 1);
                } else {
                  display = '0';
                }
              } else if (val == '+' || val == '-' || val == '×' || val == '÷' || val == '%') {
                firstNum = double.tryParse(display) ?? 0;
                if (val == '%') {
                  display = (firstNum / 100).toString();
                  shouldReset = true;
                } else {
                  operator = val;
                  shouldReset = true;
                }
              } else if (val == '=') {
                double secondNum = double.tryParse(display) ?? 0;
                double res = secondNum;
                if (operator == '+') res = firstNum + secondNum;
                if (operator == '-') res = firstNum - secondNum;
                if (operator == '×') res = firstNum * secondNum;
                if (operator == '÷') res = secondNum != 0 ? firstNum / secondNum : 0;
                display = res.toStringAsFixed(res.truncateToDouble() == res ? 0 : 2);
                operator = '';
                shouldReset = true;
              } else {
                if (shouldReset || display == '0') {
                  display = val == '.' ? '0.' : val;
                  shouldReset = false;
                } else {
                  if (val == '.' && display.contains('.')) return;
                  display += val;
                }
              }
            });
          }

          Widget calcBtn(String label, {Color? bg, Color? fg}) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg ?? const Color(0xFF2B2B2B),
                    foregroundColor: fg ?? Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => onPress(label),
                  child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }

          return Directionality(
            textDirection: TextDirection.ltr,
            child: AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.amberAccent, width: 1.5),
              ),
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.calculate, color: Colors.amberAccent),
                  Text('آلة حاسبة متكاملة', style: TextStyle(color: Colors.amberAccent, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101010),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (operator.isNotEmpty)
                            Text('$firstNum $operator',
                                style: const TextStyle(color: Colors.amberAccent, fontSize: 13)),
                          SelectableText(
                            display,
                            style: const TextStyle(
                                color: Colors.cyanAccent, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      calcBtn('C', bg: Colors.red.shade800),
                      calcBtn('⌫', bg: Colors.blueGrey.shade700),
                      calcBtn('%', bg: Colors.amber.shade800, fg: Colors.black),
                      calcBtn('÷', bg: Colors.amber.shade800, fg: Colors.black),
                    ]),
                    Row(children: [
                      calcBtn('7'),
                      calcBtn('8'),
                      calcBtn('9'),
                      calcBtn('×', bg: Colors.amber.shade800, fg: Colors.black),
                    ]),
                    Row(children: [
                      calcBtn('4'),
                      calcBtn('5'),
                      calcBtn('6'),
                      calcBtn('-', bg: Colors.amber.shade800, fg: Colors.black),
                    ]),
                    Row(children: [
                      calcBtn('1'),
                      calcBtn('2'),
                      calcBtn('3'),
                      calcBtn('+', bg: Colors.amber.shade800, fg: Colors.black),
                    ]),
                    Row(children: [
                      calcBtn('00'),
                      calcBtn('0'),
                      calcBtn('.'),
                      calcBtn('=', bg: Colors.green.shade700),
                    ]),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const CustomScreenAppBar(title: 'المساعد الذكي العقاري المتكامل'),
        body: Column(
          children: [
            // شريط علوي يضم زر الآلة الحاسبة المتكاملة والمقترحات المفيدة
            Container(
              height: 48,
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ActionChip(
                    backgroundColor: Colors.amber.shade700,
                    avatar: const Icon(Icons.calculate, color: Colors.black, size: 16),
                    label: const Text(
                      'آلة حاسبة متكاملة',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: _showIntegratedCalculator,
                  ),
                  const SizedBox(width: 8),
                  ..._quickPrompts.map((prompt) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ActionChip(
                          backgroundColor: const Color(0xFF2B2B2B),
                          side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                          label: Text(
                            prompt.toString(),
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                          ),
                          onPressed: () => _sendMessage(prompt.toString()),
                        ),
                      )),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  bool isUser = msg['sender'] == 'user';
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.teal.shade800 : const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUser ? Colors.teal.shade600 : Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: SelectableText(
                        msg['text'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isListening)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.red.shade900.withValues(alpha: 0.85),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.graphic_eq, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'جاري الاستماع لصوتك... تحدث الآن بالعامية المصرية',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(color: Colors.amberAccent),
              ),
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFF181818),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: _isListening ? Colors.redAccent : Colors.amber.shade700,
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: _isListening ? Colors.white : Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'باسمعك... اتكلم دلوقتي'
                            : 'اكتب سؤالك أو اضغط على الميكروفون واتكلم...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: const Color(0xFF252525),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.amberAccent),
                    onPressed: () => _sendMessage(),
                    tooltip: 'إرسال',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}