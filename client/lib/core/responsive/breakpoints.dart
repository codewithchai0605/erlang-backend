/// Layout thresholds (logical pixels). Phones use one pane; wide windows (tablets, Windows) show the
/// conversation list and the open chat side by side.
class Breakpoints {
  const Breakpoints._();
  static const double twoPane = 720;
  static const double maxFormWidth = 420;
  static const double listPaneWidth = 360;

  static bool isTwoPane(double width) => width >= twoPane;
}
