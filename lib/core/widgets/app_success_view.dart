import 'app_state_view.dart';

class AppSuccessView extends AppStateView {
  const AppSuccessView({
    super.key,
    super.title = 'Success',
    super.message,
    super.actionLabel,
    super.onAction,
  }) : super(status: UiStatus.success);
}
