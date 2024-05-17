library versionize;

import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:xml/xml.dart' as xml;

class Versionize {
  final String pubspecPath;
  final String androidGradlePath;
  final String iosPlistPath;
  final String iosProjectPath;

  Versionize({
    this.pubspecPath = 'pubspec.yaml',
    this.androidGradlePath = 'android/app/build.gradle',
    this.iosPlistPath = 'ios/Runner/Info.plist',
    this.iosProjectPath = 'ios/Runner.xcodeproj/project.pbxproj',
  });

  Future<void> updateVersion({required bool updateAndroid, required bool updateIOS}) async {
    final newVersion = await _getNewVersion();
    if (updateAndroid) {
      await _updateAndroidVersion(newVersion);
    }
    if (updateIOS) {
      await _updateIOSVersion(newVersion);
    }
  }

  Future<String> _getNewVersion() async {
    final pubspecFile = File(pubspecPath);
    final content = await pubspecFile.readAsString();
    final yamlMap = loadYaml(content) as Map;
    final currentVersion = yamlMap['version'] as String;
    final versionParts = currentVersion.split('+');
    final versionNumber = versionParts[0];
    final buildNumber = int.parse(versionParts[1]);
    final newBuildNumber = buildNumber + 1;
    final newVersion = '$versionNumber+$newBuildNumber';
    final updatedContent = content.replaceAll(RegExp(r'version: \S+'), 'version: $newVersion');
    await pubspecFile.writeAsString(updatedContent);
    return newVersion;
  }

  Future<void> _updateAndroidVersion(String newVersion) async {
    final versionParts = newVersion.split('+');
    final versionName = versionParts[0];
    final versionCode = int.parse(versionParts[1]);

    final gradleFile = File(androidGradlePath);
    final content = await gradleFile.readAsString();
    final updatedContent = content.replaceAll(RegExp(r'versionName "\S+"'), 'versionName "$versionName"').replaceAll(RegExp(r'versionCode \d+'), 'versionCode $versionCode');
    await gradleFile.writeAsString(updatedContent);
  }

  Future<void> _updateIOSVersion(String newVersion) async {
    final versionParts = newVersion.split('+');
    final versionNumber = versionParts[0];
    final buildNumber = versionParts[1];

    await _updateIOSPlistVersion(versionNumber, buildNumber);
    await _updateIOSProjectVersion(buildNumber);
  }

  Future<void> _updateIOSPlistVersion(String versionNumber, String buildNumber) async {
    final plistFile = File(iosPlistPath);
    final content = await plistFile.readAsString();
    final document = xml.parse(content);

    final versionKey = document.findAllElements('key').firstWhere((element) => element.text == 'CFBundleShortVersionString').nextElementSibling!;
    final buildKey = document.findAllElements('key').firstWhere((element) => element.text == 'CFBundleVersion').nextElementSibling!;

    versionKey.innerText = versionNumber;
    buildKey.innerText = buildNumber;

    await plistFile.writeAsString(document.toXmlString(pretty: true));
  }

  Future<void> _updateIOSProjectVersion(String buildNumber) async {
    final projectFile = File(iosProjectPath);
    final content = await projectFile.readAsString();
    final updatedContent = content.replaceAll(RegExp(r'CURRENT_PROJECT_VERSION = \S+;'), 'CURRENT_PROJECT_VERSION = $buildNumber;');
    await projectFile.writeAsString(updatedContent);
  }
}
