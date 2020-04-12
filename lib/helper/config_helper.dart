import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

var config;

// get bookmarks from local storage file
Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  // print(directory.path);
  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/cfig.json');
}

Future getCognigyConfig() async {
  try {
    final file = await _localFile;
    // Read the file

    var fileData = await file.readAsString();

    if (fileData == null || fileData == '') {
      config = {'socketUrl': 'https://endpoint-internal.cognigy.ai/', 'urlToken': '849de509618869b1cf5d14855354b7b81ceb43bd5f5d4a6e72080ddaed9bc3ea'};
    } else {
      config = await json.decode(fileData);
    }

    print(config);

    return config;
  } catch (e) {
    // If encountering an error, return
    return {'socketUrl': 'https://endpoint-internal.cognigy.ai/', 'urlToken': '849de509618869b1cf5d14855354b7b81ceb43bd5f5d4a6e72080ddaed9bc3ea'};
  }
}


Future<File> setCognigyConfig(String socketUrl, String urlToken) async {
  config = {'socketUrl': socketUrl, 'urlToken': urlToken};

  final file = await _localFile;
  // Write the file
  return file.writeAsString(json.encode(config));
}
