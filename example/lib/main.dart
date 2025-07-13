import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:fast_style_transfer_flutter/fast_style_transfer_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fast style transfer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Fast style transfer Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FastStyleTransferFlutter _fastStyleTransferFlutter;

  Uint8List? result;

  Uint8List ? file;

  int _selectedIndex = 0;

  Future<Uint8List> getStyleToBytes(int index) async {
    final String basePath = 'assets/styles';
    final String path = '$basePath/style$index.jpg';
    ByteData data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  @override
  void initState() {
    super.initState();

    _fastStyleTransferFlutter = FastStyleTransferFlutter.init(
      config: FastStyleTransferConfig(
        loaderConfig: FastStyleAssetsLoaderConfig(
          predictResource: 'assets/models/prediction.tflite',
          styleTransferResource: 'assets/models/transfer.tflite',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fastStyleTransferFlutter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child:
                  result == null
                      ? Center(
                        child: ElevatedButton(
                          onPressed: _onPickImage,
                          child: Text('Pick image'),
                        ),
                      )
                      : Image(image: MemoryImage(result!), fit: BoxFit.contain),
            ),

            const SizedBox(height: 30),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24
                ),
                height: 150,
                child: Row(
                  children: List.generate(24, (index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _onSelectStyle(index);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Image(
                                image: AssetImage('assets/styles/style$index.jpg'),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            child:
                            _selectedIndex == index
                                ? Icon(Icons.check, color: Colors.green, size: 24,)
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _onSelectStyle(int index)async{
    _selectedIndex = index;

    setState(() {

    });

    if(file != null){
      final style = await getStyleToBytes(_selectedIndex);

      final result = await _fastStyleTransferFlutter.run(
        request: RunTransferRequest(
          image: file!,
          style: style,
        ),
      );

      setState(() {
        this.result = result;
      });
    }

  }

  void _onPickImage() async {
    try {
      ImagePicker picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);

      if (file != null) {
        final style = await getStyleToBytes(_selectedIndex);

        final fileBytes =  await file.readAsBytes();

        final result = await _fastStyleTransferFlutter.run(
          request: RunTransferRequest(
            image: fileBytes,
            style: style,
          ),
        );

        setState(() {
          this.result = result;
          this.file = fileBytes;
        });
      }
    } catch (e) {
      print('error ${e.toString()}');
    }
  }
}
