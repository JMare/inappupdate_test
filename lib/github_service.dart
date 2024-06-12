import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubService {
  final String owner;
  final String repo;

  GitHubService({required this.owner, required this.repo});

  Future<List<Release>> fetchReleases() async {
    final url = 'https://api.github.com/repos/$owner/$repo/releases';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> releasesJson = json.decode(response.body);
      return releasesJson.map((json) => Release.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load releases');
    }
  }
}

class Release {
  final String tagName;
  final String name;
  final List<Asset> assets;

  Release({required this.tagName, required this.name, required this.assets});

  factory Release.fromJson(Map<String, dynamic> json) {
    var assetsJson = json['assets'] as List;
    List<Asset> assetsList = assetsJson.map((i) => Asset.fromJson(i)).toList();

    return Release(
      tagName: json['tag_name'],
      name: json['name'],
      assets: assetsList,
    );
  }
}

class Asset {
  final String name;
  final String browserDownloadUrl;

  Asset({required this.name, required this.browserDownloadUrl});

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      name: json['name'],
      browserDownloadUrl: json['browser_download_url'],
    );
  }
}