import 'app_state_view.dart';

class EmptyState extends AppStateView {
  const EmptyState({
    super.key,
    required super.title,
    super.message,
    super.actionLabel,
    super.onAction,
  }) : super(status: UiStatus.empty);
}
