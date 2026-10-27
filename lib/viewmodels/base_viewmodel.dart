import 'package:flutter/foundation.dart';

import '../models/app_state.dart';

/// Base ViewModel with [AsyncViewState] lifecycle.
///
/// All screen ViewModels extend this class and implement [loadData].
/// In the Integrate phase, services will be injected via constructor.
class BaseViewModel<T> extends ChangeNotifier {
  AsyncViewState<T> _state = const AsyncViewState.loading();

  AsyncViewState<T> get state => _state;

  @protected
  void setState(AsyncViewState<T> newState) {
    _state = newState;
    notifyListeners();
  }

  /// Override in subclasses to fetch data from services.
  Future<void> loadData() async {}
}
