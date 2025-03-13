import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';
import 'package:todo_list_app/main.dart';

// Generate mocks with mockito
@GenerateMocks([SharedPreferences])
import 'todo_repository_test.mocks.dart';

// Define the MockedTodoRepository at the top level, outside any test groups
class MockedTodoRepository extends TodoRepository {
  final SharedPreferences prefs;
  
  MockedTodoRepository(this.prefs);
  
  @override
  Future<SharedPreferences> getInstance() async {
    return prefs;
  }
}

void main() {
  // Test Group 1: Regular Unit Tests for TodoRepository
  group('TodoRepository Tests', () {
    late TodoRepository repository;
    
    setUp(() {
      repository = TodoRepository();
    });

    // Test 1: Save and Load Todo List
    test('should save and load todo list', () async {
      // Setup SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      // Create test data
      final todoList = [
        TodoItem(
          id: '1',
          title: 'Test Todo 1',
          isCompleted: false,
        ),
        TodoItem(
          id: '2',
          title: 'Test Todo 2',
          isCompleted: true,
        ),
      ];
      
      // Save the todo list
      await repository.saveTodoList(todoList);
      
      // Load the todo list
      final loadedTodoList = await repository.loadTodoList();
      
      // Verify the loaded list matches the original
      expect(loadedTodoList.length, equals(2));
      expect(loadedTodoList[0].id, equals('1'));
      expect(loadedTodoList[0].title, equals('Test Todo 1'));
      expect(loadedTodoList[0].isCompleted, equals(false));
      expect(loadedTodoList[1].id, equals('2'));
      expect(loadedTodoList[1].title, equals('Test Todo 2'));
      expect(loadedTodoList[1].isCompleted, equals(true));
    });

    // Test 2: Clear Todo List
    test('should clear todo list', () async {
      // Setup SharedPreferences for testing with initial data
      final testTodoJsonString = jsonEncode({
        'id': '1',
        'title': 'Test Todo',
        'isCompleted': false,
      });
      
      SharedPreferences.setMockInitialValues({
        'todo_list': [testTodoJsonString],
      });
      
      // Verify initial data is loaded
      final initialTodoList = await repository.loadTodoList();
      expect(initialTodoList.length, equals(1));
      
      // Clear the todo list
      await repository.clearTodos();
      
      // Verify the list is empty after clearing
      final emptyTodoList = await repository.loadTodoList();
      expect(emptyTodoList.length, equals(0));
    });
  });
  
  // Test Group 2: Mocked Unit Tests
  group('TodoRepository Mocked Tests', () {
    late MockSharedPreferences mockPrefs;
    late TodoRepository repository;
    
    setUp(() {
      mockPrefs = MockSharedPreferences();
      repository = MockedTodoRepository(mockPrefs);
    });
    
    // Test 3: Load Todo List from Mocked SharedPreferences
    test('should load todo list from mocked shared preferences', () async {
      // Setup mock data
      final mockTodoItems = [
        jsonEncode({
          'id': 'mock1',
          'title': 'Mock Todo 1',
          'isCompleted': false,
        }),
        jsonEncode({
          'id': 'mock2',
          'title': 'Mock Todo 2',
          'isCompleted': true,
        }),
      ];
      
      // Setup mock behavior
      when(mockPrefs.getStringList('todo_list'))
          .thenReturn(mockTodoItems);
      
      // Load the todo list
      final loadedTodoList = await repository.loadTodoList();
      
      // Verify the loaded list matches the mock data
      expect(loadedTodoList.length, equals(2));
      expect(loadedTodoList[0].id, equals('mock1'));
      expect(loadedTodoList[0].title, equals('Mock Todo 1'));
      expect(loadedTodoList[0].isCompleted, equals(false));
      expect(loadedTodoList[1].id, equals('mock2'));
      expect(loadedTodoList[1].title, equals('Mock Todo 2'));
      expect(loadedTodoList[1].isCompleted, equals(true));
      
      // Verify the mock was called
      verify(mockPrefs.getStringList('todo_list')).called(1);
    });
  });
}