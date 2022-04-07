import 'package:flutter/material.dart';

import 'node_ux.dart';

extension DeepestNodeUx on NodeUx {
  /// Возвращает конечный открытый узел текущего дерева
  ///
  /// Метод ниже выводит на экран все типы конечных узлов
  /// дерева в прямом, а затем, в обратном порядке.
  ///
  ///```dart
  ///   void testDeepestChild() {
  ///    print("testDeepestChild()");
  ///    var deepest = root.firstDeepestChild;
  ///    while (deepest != null) {
  ///      print("\t\t\t${deepest.runtimeType}");
  ///      deepest = deepest.nextDeepestChild;
  ///    }
  ///    print("===");
  ///    deepest = root.lastDeepestChild;
  ///    while (deepest != null) {
  ///      print("\t\t\t${deepest.runtimeType}");
  ///      deepest = deepest.prevDeepestChild;
  ///    }
  ///    print("testDeepestChild() — end");
  ///  }
  /// ```

  NodeUx? get deepestOpenedChild {
    NodeUx? visitor = root; // ignore: invalid_use_of_protected_member
    while (visitor?.openedChild != null) {
      visitor = visitor?.openedChild;
    }
    return visitor;
  }

  /// Возвращает первый конечный узел текущего узла.
  /// Если текущий узел является конечным, то он и будет возвращен.
  @protected
  NodeUx? get firstDeepestChild {
    NodeUx? visitor = this;
    while (visitor?.firstChild != null) { // ignore: invalid_use_of_protected_member
      visitor = visitor?.firstChild; // ignore: invalid_use_of_protected_member
    }
    return visitor;
  }

  /// Возвращает последний конечный узел текущего узла.
  /// Если текущий узел является конечным, то он и будет возвращен.
  @protected
  NodeUx? get lastDeepestChild {
    NodeUx? visitor = this;
    while (visitor?.lastChild != null) { // ignore: invalid_use_of_protected_member
      visitor = visitor?.lastChild; // ignore: invalid_use_of_protected_member
    }
    return visitor;
  }

  /// Возвращает следующий конечный узел от текущего узла.
  /// Если текущий узел сам не является конечным узлом,
  /// то будет возвращен конечный узел следующий за первым
  /// конечным узлом.
  @protected
  NodeUx? get nextDeepestChild {
    NodeUx? visitor = firstDeepestChild;
    if (visitor?.nextSibling != null) return visitor?.nextSibling; // ignore: invalid_use_of_protected_member
    while (visitor?.nextSibling == null && visitor?.parent != null) { // ignore: invalid_use_of_protected_member
      visitor = visitor?.parent as NodeUx; // ignore: invalid_use_of_protected_member
    }
    return visitor?.nextSibling?.firstDeepestChild; // ignore: invalid_use_of_protected_member
  }

  /// Возвращает предыдущий конечный узел от текущего узла.
  /// Если текущий узел сам не является конечным узлом,
  /// то будет возвращен конечный узел предыдущий первому
  /// конечному узлу.
  @protected
  NodeUx? get prevDeepestChild {
    NodeUx? visitor = firstDeepestChild;
    if (visitor?.prevSibling != null) return visitor?.prevSibling; // ignore: invalid_use_of_protected_member
    while (visitor?.prevSibling == null && visitor?.parent != null) { // ignore: invalid_use_of_protected_member
      visitor = visitor?.parent as NodeUx; // ignore: invalid_use_of_protected_member
    }
    return visitor?.prevSibling?.lastDeepestChild; // ignore: invalid_use_of_protected_member
  }

}
