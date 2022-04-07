import 'package:flutter/material.dart';

import 'node_ux.dart';

class NotifierUx extends ValueNotifier {
  NotifierUx(NodeUx value) : super(value);

  void notify() => notifyListeners();
}
