import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:tripx_frontend/repositories/translator_repository.dart';
import 'package:tripx_frontend/screens/translator/language_data.dart';
import 'package:tripx_frontend/screens/translator/language_selection_screen.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _translatedController = TextEditingController();
  final TranslatorRepository _repository = TranslatorRepository();
  final Logger _logger = Logger();

  String _sourceLanguageCode = 'en';
  String _targetLanguageCode = 'hi';
  bool _isLoading = false;
  final List<Map<String, String>> _history = [];

  // Voice translation state
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _speechToTextAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  void _initializeVoice() async {
    _speechToTextAvailable = await _speechToText.initialize(
      onError: (error) =>
          _logger.e('Speech recognition error: ${error.errorMsg}'),
      onStatus: (status) => _logger.i('Speech recognition status: $status'),
    );
    if (mounted) setState(() {}); // Update icon state
    await _flutterTts.setSharedInstance(true);
  }

  void _startListening() async {
    if (!_speechToTextAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Speech recognition not available. Please check permissions.')));
      return;
    }
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _sourceController.text = result.recognizedWords;
            });
            if (result.finalResult) {
              setState(() => _isListening = false);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
        );
      }
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _speak(String text, String langCode) async {
    if (text.isNotEmpty && !_translatedController.text.startsWith('Error')) {
      await _flutterTts.setLanguage(langCode);
      await _flutterTts.speak(text);
    }
  }

  Future<void> _translate() async {
    if (_sourceController.text.trim().isEmpty) {
      _translatedController.clear();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _translatedController.text = 'Translating...';
    });

    try {
      final result = await _repository.translateText(
        text: _sourceController.text.trim(),
        sourceLanguage: availableLanguages[_sourceLanguageCode]!,
        targetLanguage: availableLanguages[_targetLanguageCode]!,
      );
      if (mounted) {
        setState(() {
          _translatedController.text = result;
          if (_history.isEmpty ||
              _history.first['source'] != _sourceController.text.trim()) {
            _history.insert(0, {
              'source': _sourceController.text.trim(),
              'translated': result,
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translatedController.text = 'Error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _swapLanguages() {
    setState(() {
      final tempCode = _sourceLanguageCode;
      _sourceLanguageCode = _targetLanguageCode;
      _targetLanguageCode = tempCode;

      final tempText = _sourceController.text;
      _sourceController.text =
          (_translatedController.text.startsWith('Error') ||
                  _translatedController.text == 'Translating...')
              ? ''
              : _translatedController.text;
      _translatedController.text = tempText;
    });
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _translatedController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translator'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Column(
        children: [
          _buildLanguageSelectorRow(context),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(flex: 2, child: _buildSourceCard()),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(flex: 3, child: _buildTranslatedCard()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _translate,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.translate),
      ),
    );
  }

  Widget _buildLanguageSelectorRow(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _buildLanguageButton(context, isSource: true)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
              onPressed: _swapLanguages,
            ),
          ),
          Expanded(child: _buildLanguageButton(context, isSource: false)),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, {required bool isSource}) {
    final langCode = isSource ? _sourceLanguageCode : _targetLanguageCode;
    final langName = availableLanguages[langCode] ?? 'Select';

    return OutlinedButton(
      onPressed: () async {
        final selectedLangCode = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => LanguageSelectionScreen(
              selectedLanguageCode: langCode,
            ),
          ),
        );
        if (selectedLangCode != null && mounted) {
          setState(() {
            if (isSource) {
              _sourceLanguageCode = selectedLangCode;
            } else {
              _targetLanguageCode = selectedLangCode;
            }
          });
        }
      },
      child: Text(langName),
    );
  }

  Widget _buildSourceCard() {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _sourceController,
                maxLines: null,
                expands: true,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Enter text...',
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  border: InputBorder.none,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _speechToTextAvailable
                      ? (_isListening ? _stopListening : _startListening)
                      : null,
                  color: _speechToTextAvailable
                      ? (_isListening
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary)
                      : theme.colorScheme.onSurface.withOpacity(0.38),
                ),
                if (_sourceController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: theme.colorScheme.primary),
                    onPressed: () {
                      _sourceController.clear();
                      _translatedController.clear();
                    },
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTranslatedCard() {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withOpacity(0.7),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading && _translatedController.text == 'Translating...')
              Center(
                  child: Text("Translating...",
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6))))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _translatedController.text.isEmpty
                        ? "Translation"
                        : _translatedController.text,
                    style: TextStyle(
                      fontSize: 20,
                      color: _translatedController.text.startsWith('Error:')
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                      fontStyle: _translatedController.text.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
              ),
            if (_translatedController.text.isNotEmpty &&
                !_translatedController.text.startsWith('Error:') &&
                !_isLoading)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up_outlined,
                        color: theme.colorScheme.primary),
                    onPressed: () => _speak(
                      _translatedController.text,
                      _targetLanguageCode,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: theme.colorScheme.primary),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _translatedController.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Copied to clipboard'),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
