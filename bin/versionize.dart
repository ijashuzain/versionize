import 'package:args/args.dart';
import 'package:versionize/versionize.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag('ios', negatable: false, help: 'Update iOS version')
    ..addFlag('android', negatable: false, help: 'Update Android version')
    ..addCommand('update');

  final results = parser.parse(args);

  if (results.command?.name == 'update') {
    var updateIOS = results['ios'] ?? false;
    var updateAndroid = results['android'] ?? false;

    if (!updateIOS && !updateAndroid) {
      // If neither --ios nor --android is provided, update both
      updateIOS = true;
      updateAndroid = true;
    }

    final versionize = Versionize();
    versionize.updateVersion(updateAndroid: updateAndroid, updateIOS: updateIOS).then((_) {
      print('Version updated successfully');
    }).catchError((error) {
      print('Error updating version: $error');
    });
  } else {
    print('Usage: dart pub run versionize update [--ios] [--android]');
  }
}
