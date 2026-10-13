import 'app_state_view.dart';

class AppErrorView extends AppStateView {
  const AppErrorView({
    super.key,
    super.title = 'Something went wrong',
    super.message,
    super.actionLabel,
    super.onAction,
  }) : super(status: UiStatus.error);
}
