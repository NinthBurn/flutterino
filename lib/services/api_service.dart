import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:techware_flutter/models/ComputerComponent.dart';
import 'package:techware_flutter/services/database_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

var logger = Logger();

class ApiService {
  static final ApiService _instance = ApiService._constructor();
  static const String baseUrl = 'http://172.30.250.88:5000/api/computer-components';
  static const String socketUrl = 'ws://172.30.250.88:5000';
  static const Duration socketTimeout = Duration(seconds: 1);
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _changesSynced = false;
  final StreamController<Map<String, dynamic>> _socketController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get socketStream => _socketController.stream;

  ApiService._constructor();

  factory ApiService() => _instance;

  Future<bool> checkWebSocketConnection() async {
    return _isConnected;
  }

  Future<bool> connectWebSocket() async {
    Completer<bool> completer = Completer<bool>();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(socketUrl));

      await Future.any([
        _channel!.ready.then((onValue) {
          if(!_changesSynced) {
            _isConnected = true;
            completer.complete(true);

          }
          logger.i("WebSocket connection established.");
        }).catchError((error) {
          _isConnected = false;
          _changesSynced = false;
          logger.w("WebSocket connection failed: $error");
          completer.complete(false);
        }),

        Future.delayed(socketTimeout, () {
          if (!completer.isCompleted) {
            logger.w("WebSocket connection timed out.");
            completer.complete(false);
          }
        }),
      ]);

      _channel!.stream.listen((message) {
        final data = json.decode(message);
        _socketController.add(data);

        logger.i("Data has changed on the server, updating local data.");

        final changeType = data['type'];
        final componentData = data['data'];

        if (changeType == 'add') {
          _addComponentLocally(componentData);
        } else if (changeType == 'update') {
          _updateComponentLocally(componentData);
        } else if (changeType == 'delete') {
          _deleteComponentLocally(componentData['product_id']);
        }

      }, onDone: () {
        _isConnected = false;
        _changesSynced = false;
        logger.w("WebSocket connection closed.");
        if (!completer.isCompleted) {
          completer.complete(false);
        }

      }, onError: (error) {
        _isConnected = false;
        _changesSynced = false;
        logger.w("WebSocket connection error: $error");
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      return completer.future;
    } catch (e) {
      logger.w("WebSocket connection error: $e");
      _isConnected = false;
      _changesSynced = false;
      return Future.value(false);
    }
  }

  Future<void> _addComponentLocally(Map<String, dynamic> componentData) async {
    try {
      ComputerComponent component = ComputerComponent.fromJson(componentData);
      await DatabaseService.instance.addComponent(component);
      logger.i("Component added locally: ${component.toString()}");
    } catch (e) {
      logger.i("Error adding component locally: $e");
      rethrow;
    }
  }

  Future<void> _updateComponentLocally(Map<String, dynamic> componentData) async {
    try {
      ComputerComponent component = ComputerComponent.fromJson(componentData);
      await DatabaseService.instance.updateComponent(component);
      logger.i("Component updated locally: ${component.toString()}");
    } catch (e) {
      logger.w("Error updating component locally: $e");
      rethrow;
    }
  }

  Future<void> _deleteComponentLocally(int productId) async {
    try {
      await DatabaseService.instance.deleteComponent(productId);
      logger.i("Component deleted locally with id: $productId");
    } catch (e) {
      logger.w("Error deleting component locally: $e");
      rethrow;
    }
  }

  Future<int> addComponent(ComputerComponent component) async {
    bool connected = await checkWebSocketConnection();

    if (connected) {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(component.toJsonWithoutId()),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['product_id'];
      } else {
        throw Exception('Failed to add component to server.');
      }
    } else {
      logger.w('Failed to connect to the server, saving the changes locally');
      return DatabaseService.instance.addComponentOffline(component);
    }
  }

  Future<List<ComputerComponent>> getAllComponents() async {
    if (await checkWebSocketConnection()) {
      if(!_changesSynced) {
        _changesSynced = true;
        await syncOfflineChanges();
      }

      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        await DatabaseService.instance.clearAllComponents();

        List<ComputerComponent> components = [];

        for (var componentData in jsonResponse) {
          ComputerComponent component = ComputerComponent.fromJson(componentData);
          components.add(component);
          await DatabaseService.instance.addComponent(component);
        }

        logger.i("Fetched data from server");
        return components;
        // return jsonResponse.map((e) => ComputerComponent.fromJson(e)).toList();
      } else {
        throw Exception('Failed to fetch components from server.');
      }

    } else {
      logger.w("Not connected to server");
      return DatabaseService.instance.getAllComponents();
    }
  }

  Future<int> updateComponent(ComputerComponent component) async {
    bool connected = await checkWebSocketConnection();

    if (connected) {
      final response = await http.put(
        Uri.parse('$baseUrl/${component.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(component.toJsonWithoutId()),
      );

      if (response.statusCode == 200) {
        return 1;
      } else {
        throw Exception('Failed to update component on server.');
      }

    } else {
      logger.w("Not connected to server");
      await DatabaseService.instance.updateComponentOffline(component);
      return -1;
    }
  }

  Future<int> deleteComponent(int id) async {
    bool connected = await checkWebSocketConnection();

    if (connected) {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        return 1;
      } else {
        throw Exception('Failed to delete component from server.');
      }
    } else {
      logger.w("Not connected to server");
      DatabaseService.instance.deleteComponentOffline(id);
      return -1;
    }
  }

  Future<void> syncOfflineChanges() async {
    List<Map<String, dynamic>> offlineChanges = await DatabaseService.instance.getOfflineChanges();

    for (var change in offlineChanges) {
      String changeType = change['change_type'];
      int productId = change['product_id'];
      String data = change['data'];

      try {
        if (changeType == 'add') {
          var componentData = json.decode(data);
          final response = await http.post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(componentData),
          );
          if (response.statusCode == 200) {
            await DatabaseService.instance.markChangeAsSynced(change['id']);
          }

        } else if (changeType == 'update') {
          var componentData = json.decode(data);
          final response = await http.put(
            Uri.parse('$baseUrl/$productId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(componentData),
          );
          if (response.statusCode == 200) {
            await DatabaseService.instance.markChangeAsSynced(change['id']);
          }

        } else if (changeType == 'delete') {
          final response = await http.delete(Uri.parse('$baseUrl/$productId'));
          if (response.statusCode == 200) {
            await DatabaseService.instance.markChangeAsSynced(change['id']);
          }
        }

      } catch (e) {
        logger.e("Failed to sync offline change: $e");
      }
    }

    await DatabaseService.instance.clearOfflineChanges();
  }
}
