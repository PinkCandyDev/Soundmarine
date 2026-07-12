import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/track_list.dart';

class ApiService {
  static String baseUrl = '';
  static String? token;

  static Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Album>> getAlbums() async {
    http.Response response = await http.get(
      Uri.parse('$baseUrl/api/albums'),
      headers: await _getHeaders(),
    );
    List<dynamic> json = jsonDecode(response.body);
    return json.map((dynamic e) => Album.fromJson(e)).toList();
  }

  static Future<List<Playlist>> getPlaylists() async {
    http.Response response = await http.get(
      Uri.parse('$baseUrl/api/playlists'),
      headers: await _getHeaders(),
    );
    debugPrint('Playlists status: ${response.statusCode}');
    debugPrint('Playlists body: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Failed to load playlists: ${response.statusCode}');
    }
    List<dynamic> json = jsonDecode(response.body);
    return json.map((dynamic e) => Playlist.fromJson(e)).toList();
  }

  static Future<List<Track>> getAlbumTracks(String albumId) async {
    http.Response response = await http.get(
      Uri.parse('$baseUrl/api/albums/$albumId/tracks'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load tracks: ${response.statusCode}');
    }
    List<dynamic> json = jsonDecode(response.body);
    return json.map((dynamic e) => Track.fromJson(e)).toList();
  }

  static Future<List<Track>> getPlaylistTracks(String playlistId) async {
    http.Response response = await http.get(
      Uri.parse('$baseUrl/api/playlists/$playlistId/tracks'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load tracks: ${response.statusCode}');
    }
    List<dynamic> json = jsonDecode(response.body);
    return json.map((dynamic e) => Track.fromJson(e)).toList();
  }

  static Future<String> getArtistById(String id) async {
    http.Response response = await http.get(
      Uri.parse('$baseUrl/api/artist/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return response.body;
    throw Exception('Failed to load artist');
  }

  static Future<String> login(String username, String password) async {
    http.Response response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode != 200) throw Exception('Login failed: ${response.statusCode} ${response.body}');
    Map<String, dynamic> json = jsonDecode(response.body);
    return json['token'];
  }

  static Future<List<TrackList>> getLikedTracks() async {
    http.Response response = await http.get(
      Uri.parse('$baseUrl/api/liked'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load liked tracks: ${response.statusCode}');
    }
    List<dynamic> json = jsonDecode(response.body);
    return json.map((dynamic e) => TrackList.fromJson(e)).toList();
  }

  static Future<void> likeTrack(String trackId) async {
    http.Response response = await http.post(
      Uri.parse('$baseUrl/api/liked/$trackId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to like track: ${response.statusCode}');
    }
  }

  static Future<void> unlikeTrack(String trackId) async {
    http.Response response = await http.delete(
      Uri.parse('$baseUrl/api/liked/$trackId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to unlike track: ${response.statusCode}');
    }
  }
}