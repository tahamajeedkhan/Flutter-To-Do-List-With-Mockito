import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(),
    );
  }
}

// Todo Item Model
class TodoItem {
  String id;
  String title;
  bool isCompleted;

  TodoItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  // Convert TodoItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  // Create TodoItem from JSON
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'],
    );
  }
}

// Todo Repository for Shared Preferences
class TodoRepository {
  static const String _todoListKey = 'todo_list';

  // Method to get SharedPreferences (can be overridden in tests)
  Future<SharedPreferences> getInstance() async {
    return await SharedPreferences.getInstance();
  }

  // Save todo list to SharedPreferences
  Future<bool> saveTodoList(List<TodoItem> todoList) async {
    final SharedPreferences prefs = await getInstance();
    
    // Convert todo list to JSON string
    List<String> jsonStringList = todoList.map((item) => 
      jsonEncode(item.toJson())).toList();
    
    return await prefs.setStringList(_todoListKey, jsonStringList);
  }

  // Load todo list from SharedPreferences
  Future<List<TodoItem>> loadTodoList() async {
    final SharedPreferences prefs = await getInstance();
    final List<String>? jsonStringList = prefs.getStringList(_todoListKey);
    
    if (jsonStringList == null || jsonStringList.isEmpty) {
      return [];
    }
    
    // Convert JSON strings back to TodoItem objects
    return jsonStringList.map((jsonString) => 
      TodoItem.fromJson(jsonDecode(jsonString))).toList();
  }

  // Clear all todos from SharedPreferences
  Future<bool> clearTodos() async {
    final SharedPreferences prefs = await getInstance();
    return await prefs.remove(_todoListKey);
  }
}

// Main Todo List Screen
class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<TodoItem> _todoItems = [];
  final TodoRepository _repository = TodoRepository();
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodoItems();
  }

  // Load todos from repository
  Future<void> _loadTodoItems() async {
    setState(() {
      _isLoading = true;
    });
    
    final todoList = await _repository.loadTodoList();
    
    setState(() {
      _todoItems = todoList;
      _isLoading = false;
    });
  }

  // Save todos to repository
  Future<void> _saveTodoItems() async {
    await _repository.saveTodoList(_todoItems);
  }

  // Add new todo
  void _addTodoItem(String title) {
    if (title.isEmpty) return;
    
    setState(() {
      _todoItems.add(TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
      ));
      _textController.clear();
    });
    
    _saveTodoItems();
  }

  // Toggle todo completion status
  void _toggleTodoItem(String id) {
    setState(() {
      final index = _todoItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _todoItems[index].isCompleted = !_todoItems[index].isCompleted;
      }
    });
    
    _saveTodoItems();
  }

  // Delete todo
  void _deleteTodoItem(String id) {
    setState(() {
      _todoItems.removeWhere((item) => item.id == id);
    });
    
    _saveTodoItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Add a new todo',
                          ),
                          onSubmitted: _addTodoItem,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _addTodoItem(_textController.text),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _todoItems.isEmpty
                      ? Center(child: Text('No todos yet!'))
                      : ListView.builder(
                          itemCount: _todoItems.length,
                          itemBuilder: (context, index) {
                            final todo = _todoItems[index];
                            return ListTile(
                              title: Text(
                                todo.title,
                                style: TextStyle(
                                  decoration: todo.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              leading: Checkbox(
                                value: todo.isCompleted,
                                onChanged: (_) => _toggleTodoItem(todo.id),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteTodoItem(todo.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}