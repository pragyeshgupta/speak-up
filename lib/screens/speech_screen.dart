import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:avatar_glow/avatar_glow.dart';


class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button to start \n speaking';
  var wordSpoken = null;
  var parsedDefinition = null;
  var parsedExample = null;
  var parsedImage = null;

  Map<String, String> get headers => {
    "Accept": "application/json",
    "Authorization": "Token 08a5e3222b8be11a8bdcbaa455cb0f7ab1e7f608",
  };
  // var response;

  Future<Response> getResponseData(String word) async {
    var url = Uri.parse('https://owlbot.info/api/v4/dictionary/$word');
    var response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
          "Request to $url failed with status ${response.statusCode}: ${response.body}");
    }
    return response;
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            wordSpoken = val.recognizedWords;
            getResponseData(wordSpoken).then((v){
              setState(() {
                parsedDefinition = jsonDecode(v.body)['definitions'][0]['definition'];
                parsedExample = jsonDecode(v.body)['definitions'][0]['example'];
                parsedImage = jsonDecode(v.body)['definitions'][0]['image_url'];
                _text = 'Your word:\n' + wordSpoken;
              });
            });
            _isListening = false;
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });

    }
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('SpeakUp'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Colors.blueGrey,
        endRadius: 100.0,
        duration: const Duration(milliseconds: 2000),
        repeatPauseDuration: const Duration(milliseconds: 100),
        repeat: true,
        child: FloatingActionButton(
          onPressed: _listen,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
      body: Column(

        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          wordSpoken !=null ? definitionWidget('Meaning', parsedDefinition) : Container(),
          wordSpoken != null ? definitionWidget('Example', parsedExample) : Container(),

          wordSpoken != null
              ? SizedBox(
                  height: 0.3*height,
                  width: 0.3*width,
                  child: parsedImage != null ? Image.network(parsedImage) : const Image(image: AssetImage('assets/image_not_found.png')),
                )
              : Container(),
        ],
      ),
    );
  }

  Padding definitionWidget(String text, String str) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RichText(
            text:  TextSpan(
              children: [
                TextSpan(text: text + '\n',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),),
                TextSpan(
                    text: str,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w300,
                    )
                ),
              ],

            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

}