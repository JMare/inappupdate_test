import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'github_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Updater App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GitHubService githubService;
  late Future<List<Release>> futureReleases;

  @override
  void initState() {
    super.initState();
    githubService = GitHubService(owner: 'jmare', repo: 'inappupdate_test');
    futureReleases = githubService.fetchReleases();
  }

  Future<void> downloadAndInstallApk(String url, String fileName) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/$fileName';
      final file = File(filePath);

      final response = await http.get(Uri.parse(url));
      await file.writeAsBytes(response.bodyBytes);

      await OpenFile.open(filePath);
    } else {
      print('Permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Releases'),
      ),
      body: FutureBuilder<List<Release>>(
        future: futureReleases,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No releases found'));
          } else {
            final releases = snapshot.data!;
            return ListView.builder(
              itemCount: releases.length,
              itemBuilder: (context, index) {
                final release = releases[index];
                return ListTile(
                  title: Text(release.name),
                  subtitle: Text(release.tagName),
                  onTap: () {
                    final apkAsset = release.assets.firstWhere((asset) => asset.name.endsWith('.apk'));
                    downloadAndInstallApk(apkAsset.browserDownloadUrl, apkAsset.name);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
