import 'package:flutter/foundation.dart';

import '../models/app_state.dart';

/// Base ViewModel with [AsyncViewState] lifecycle.
///
/// All screen ViewModels extend this class and implement [loadData].
/// In the Integrate phase, services will be injected via constructor.
class BaseViewModel<T> extends ChangeNotifier {
  AsyncViewState<T> _state = const AsyncViewState.loading();
  String? _lastError;

  AsyncViewState<T> get state => _state;

  /// Message of the most recent failed persistence operation, if any.
  /// Cleared on the next successful operation. Never contains note/task
  /// contents — only a short operational description.
  String? get lastError => _lastError;

  @protected
  void setState(AsyncViewState<T> newState) {
    _state = newState;
    notifyListeners();
  }

  /// Records a persistence failure and notifies listeners. Never logs or
  /// stores sensitive item contents.
  @protected
  void setLastError(String message) {
    _lastError = message;
    notifyListeners();
  }

  @protected
  void clearLastError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  /// Override in subclasses to fetch data from services.
  Future<void> loadData() async {}
}
