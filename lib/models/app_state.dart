enum ViewState { loading, empty, data, error }

class AsyncViewState<T> {
  const AsyncViewState.loading() : state = ViewState.loading, data = null, message = null;
  const AsyncViewState.empty() : state = ViewState.empty, data = null, message = null;
  const AsyncViewState.data(this.data) : state = ViewState.data, message = null;
  const AsyncViewState.error(this.message) : state = ViewState.error, data = null;

  final ViewState state;
  final T? data;
  final String? message;
}
