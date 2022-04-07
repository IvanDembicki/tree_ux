import 'package:flutter/material.dart';
import '../tree_ux.dart';

enum HistoryUxPopResult { dismissModalRoute, noAction }

/// Отработка кнопки back на телефоне (не программных кнопок).
///
/// HistoryUx перехватывает это событие с помощью [WillPopScope]:
///
/// ([WillPopScope] creates a widget that registers a callback to veto
/// attempts by the user to dismiss the enclosing [ModalRoute]).
///
/// То есть, в норме кнопка back закрывает [ModalRoute], который сейчас
/// поверх всех. Но это событие отлавливаем в WillPopScope и в зависимости
/// от того, что возвращает [HistoryUxHandler], либо:
///
/// — оставляем поведение прежним, возвращая [HistoryUxPopResult.dismissModalRoute],
///
/// — блокируем закрытие соответствующего [ModalRoute], возвращая [HistoryUxPopResult.noAction].

typedef HistoryUxHandler = Future<HistoryUxPopResult> Function([BuildContext context]);

@immutable
class HistoryUxItem {
  static int counter = 0;

  final HistoryUxHandler handler;
  final String? name;
  final int num;

  HistoryUxItem({
    required this.handler,
    this.name,
  }) : num = counter++;

  Future<HistoryUxPopResult> execute(BuildContext context) async {
    print('${toString()}.execute()');
    HistoryUx.printHistory();
    return handler(context);
  }



  @override
  String toString() => '⎌ $num $name';
}
