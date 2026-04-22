import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

enum PomodoroState { idle, focusing, shortBreak, longBreak }

typedef SessionCompleteCallback = void Function(PomodoroState completedState);

class PomodoroService extends ChangeNotifier {
  // Configurable durations in minutes
  int focusDurationMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int sessionsBeforeLongBreak = 4;

  // Callbacks
  SessionCompleteCallback? onSessionComplete;

  // State
  PomodoroState _state = PomodoroState.idle;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  int _completedSessions = 0;
  int _totalFocusSeconds = 0;
  int _totalReadingSeconds = 0;
  Timer? _timer;

  PomodoroService() {
    _initSync();
  }

  void _initSync() {
    FlutterBackgroundService().on('update').listen((event) {
      _syncFromBackground();
    });
  }

  Future<void> _syncFromBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeStr = prefs.getString('pomodoro_end_time');
    
    if (endTimeStr != null) {
      final endTime = DateTime.parse(endTimeStr);
      final remaining = endTime.difference(DateTime.now());
      
      if (remaining.inSeconds > 0) {
        _remainingSeconds = remaining.inSeconds;
        // Logic to restore state
        final savedState = prefs.getString('pomodoro_state') ?? 'focusing';
        _state = _parseState(savedState);
        _totalSeconds = (prefs.getInt('pomodoro_total_seconds') ?? 0);
        
        if (!isRunning) {
          _startTimer();
        }
        notifyListeners();
      } else if (_state != PomodoroState.idle) {
        _onTimerComplete();
      }
    }
  }

  PomodoroState _parseState(String stateStr) {
    return PomodoroState.values.firstWhere(
      (e) => e.name == stateStr,
      orElse: () => PomodoroState.idle,
    );
  }

  PomodoroState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int get completedSessions => _completedSessions;
  int get totalFocusSeconds => _totalFocusSeconds;
  int get totalReadingSeconds => _totalReadingSeconds;

  double get progress {
    if (_totalSeconds == 0) return 0.0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  String get timeDisplay {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get stateLabel {
    switch (_state) {
      case PomodoroState.idle:
        return 'ابدأ';
      case PomodoroState.focusing:
        return 'وقت التركيز';
      case PomodoroState.shortBreak:
        return 'استراحة قصيرة';
      case PomodoroState.longBreak:
        return 'استراحة طويلة';
    }
  }

  String get totalFocusTimeDisplay {
    final hours = _totalFocusSeconds ~/ 3600;
    final minutes = (_totalFocusSeconds % 3600) ~/ 60;
    if (hours > 0) return '$hours ساعة $minutes د';
    return '$minutes دقيقة';
  }

  Future<void> startFocus() async {
    _state = PomodoroState.focusing;
    _totalSeconds = focusDurationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    
    await _persistState();
    _startTimer();
    FlutterBackgroundService().startService();
    notifyListeners();
  }

  Future<void> startBreak() async {
    final isLongBreak =
        _completedSessions > 0 && _completedSessions % sessionsBeforeLongBreak == 0;
    _state = isLongBreak ? PomodoroState.longBreak : PomodoroState.shortBreak;
    _totalSeconds = (isLongBreak ? longBreakMinutes : shortBreakMinutes) * 60;
    _remainingSeconds = _totalSeconds;
    
    await _persistState();
    _startTimer();
    FlutterBackgroundService().startService();
    notifyListeners();
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final endTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    await prefs.setString('pomodoro_end_time', endTime.toIso8601String());
    await prefs.setString('pomodoro_state', _state.name);
    await prefs.setString('pomodoro_state_label', stateLabel);
    await prefs.setInt('pomodoro_total_seconds', _totalSeconds);
  }

  Future<void> pause() async {
    _timer?.cancel();
    _timer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pomodoro_end_time');
    FlutterBackgroundService().invoke('stopService');
    notifyListeners();
  }

  Future<void> resume() async {
    if (_remainingSeconds > 0 && _state != PomodoroState.idle) {
      await _persistState();
      _startTimer();
      FlutterBackgroundService().startService();
      notifyListeners();
    }
  }

  Future<void> reset() async {
    _timer?.cancel();
    _timer = null;
    _state = PomodoroState.idle;
    _remainingSeconds = 0;
    _totalSeconds = 0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pomodoro_end_time');
    FlutterBackgroundService().invoke('stopService');
    notifyListeners();
  }

  void setFocusDuration(int minutes) {
    focusDurationMinutes = minutes;
    if (_state == PomodoroState.idle) {
      _remainingSeconds = 0;
      _totalSeconds = 0;
    }
    notifyListeners();
  }

  Future<void> addTime(int minutes) async {
    if (_state == PomodoroState.idle) return;
    _remainingSeconds += minutes * 60;
    _totalSeconds += minutes * 60;
    await _persistState();
    notifyListeners();
  }

  void toggleStartPause() {
    if (_state == PomodoroState.idle) {
      startFocus();
    } else if (isRunning) {
      pause();
    } else {
      resume();
    }
  }

  bool get isRunning => _timer != null && _timer!.isActive;
  bool get isPaused =>
      _state != PomodoroState.idle && !isRunning && _remainingSeconds > 0;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        if (_state == PomodoroState.focusing) {
          _totalFocusSeconds++;
        }
        
        // Share data with overlay
        FlutterOverlayWindow.shareData({
          'time': timeDisplay,
          'label': stateLabel,
        });

        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() async {
    _timer?.cancel();
    _timer = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pomodoro_end_time');
    FlutterBackgroundService().invoke('stopService');

    // Trigger completion callback
    onSessionComplete?.call(_state);

    if (_state == PomodoroState.focusing) {
      _completedSessions++;
      // Automatically transition to break
      startBreak();
    } else {
      // Break ended, go back to idle
      _state = PomodoroState.idle;
      _remainingSeconds = 0;
      _totalSeconds = 0;
      notifyListeners();
    }
  }

  void addReadingTime(int seconds) {
    _totalReadingSeconds += seconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
