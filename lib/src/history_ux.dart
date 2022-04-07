import 'package:flutter/material.dart';

import '../tree_ux.dart';
import 'history_ux_item.dart';

class HistoryUx extends StatelessWidget {
  final ViewUx child;

  static late HistoryUxItem _historyEnd;

  const HistoryUx({required this.child});

  static final List<HistoryUxItem> _history = [];

  static void pushNavigatorPop([String? name]) {
    printHistory('.pushNavigatorPop()');
    push(
      HistoryUxItem(
        name: name ?? 'Navigator pop',
        handler: ([BuildContext? context]) {
          if (context != null) {
            Navigator.pop(context);
          }
          return Future.value(HistoryUxPopResult.noAction);
        },
      ),
    );
  }

  static void push(HistoryUxItem back) {
    printHistory('.push()');
    _history.add(back);
    printHistory();
  }

  static void pushReplacement(HistoryUxItem back) {
    printHistory('.pushReplacement()');
    if (_history.isNotEmpty) {
      _history.removeLast();
    }
    push(back);
  }

  static Future<HistoryUxPopResult> pop([BuildContext? context]) async {
    printHistory('.pop()');
    if (context == null) return HistoryUxPopResult.noAction;

    HistoryUxItem item = _history.isEmpty ? _historyEnd : _history.removeLast();
    return item.execute(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: child,
      onWillPop: () async {
        HistoryUxPopResult result = await HistoryUx.pop(context);
        switch (result) {
          case HistoryUxPopResult.dismissModalRoute:
            return true;
          case HistoryUxPopResult.noAction:
            return false;
        }
      },
    );
  }

  static void setHistoryEnd(HistoryUxItem historyEnd) {
    _historyEnd = historyEnd;
  }

  static void clearHistory() {
    while (_history.isNotEmpty) {
      _history.removeLast();
    }
  }

  static void printHistory([String action = '']) {
    print('🔄 $action |-> \n\t ${_history.join('\n\t ')}');
  }
}
