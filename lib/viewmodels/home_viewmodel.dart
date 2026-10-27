import '../models/app_state.dart';
import 'base_viewmodel.dart';

class HomeViewModel extends BaseViewModel<Map<String, dynamic>> {
  HomeViewModel() {
    loadData();
  }

  @override
  Future<void> loadData() async {
    setState(const AsyncViewState.loading());
    // TODO: Fetch data from FirebaseService in Integrate phase.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    setState(const AsyncViewState.data({
      'greeting': 'Chào bạn 👋',
      'syncStatus': 'Vault sẵn sàng',
    }));
  }
}
