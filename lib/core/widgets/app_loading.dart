import 'app_state_view.dart';

class AppLoading extends AppStateView {
  const AppLoading({super.key, super.title = 'Loading', super.message})
    : super(status: UiStatus.loading);
}
