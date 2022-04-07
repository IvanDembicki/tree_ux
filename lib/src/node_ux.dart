import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../tree_ux.dart';
import 'node_ux_id_map.dart';
import 'provider_ux.dart';
import 'tree_ux_library.dart';

typedef NodeUxBuilder<P extends NodeUx> = NodeUx Function(P parent);

typedef Comparator = int Function(NodeUx a, NodeUx b);

/// Представляет состояние узла данных в иерархии состояний.
/// Дерево состояний формируется из JSON файла, состоящего
/// из узлов, которые содержат:
///
/// одно обязательное поле:
/// "type" — строка, содержащая название узла
///
/// и два необязательных:
/// "props" — объект, содержищий свойства узла
/// "children" — массив, содержащий перечень дочерних узлов
///
/// По аналогии с XML:
/// _type соответствует NodeName
/// _props соответствует списку атрибутов узла
/// _children соответствует массиву дочерних узлов
///
/// Пример JSON описания:
///```json
///      {
///       "type": "ApplicationRoot",
///       "props" : {"propertyExample": "some value"},
///       "children": [
///         {
///           "type": "FirstChildExample"
///          "children": [
///           {
///             "type": "ChildOfFirstChildExample"
///           }
///         },
///         {
///           "type": "SecondChildExample"
///         },
///         {
///           "type": "ThirdChildExample"
///         }
///       ]
///      }
///```
///
/// При старте каждый узел состояния инициирует себя и
/// рекурсивно создает дочерние узлы.
///
/// Класс предоставляет возможность доступа к другим узлам состояний
/// в иерархии, позволяет ими манипулировать — открывать, добавлять и удалять.
///
/// Если был вызван метод [_setProperty] или произведены изменения в иерархии состояний,
/// [ProviderUx] информируется о том, что произошли изменения.

abstract class _NodeUx with TreeUxEventsMember {
  static const String _TRUE = 'true';
  static const String _FALSE = 'false';

  late Map<String, dynamic>? _tempMap;

  //  📌  ▚▚▚▚▚ JSON DEFINED ▚▚▚▚▚  📌

  /// Строковый тип узла, указанный в JSON описании дерева
  @protected
  String get nodeType => _nodeType;
  late String _nodeType;

  /// Карта узлов, имеющих ID в JSON описании дерева.
  static final NodeUxIdMap _idMap = NodeUxIdMap();

  /// Регистрация узла по ID
  void _registerID() => _NodeUx._idMap.registerID(this as NodeUx, _props[IID] ?? '');

  /// Удаление регистрации узла по ID
  void _removeID() => _NodeUx._idMap.removeID(_props[IID] ?? '');

  /// Карта свойств узла, заданных в JSON описании дерева
  final Map<String, String> _props = {};

  //  📌  ▚▚▚▚▚ HIERARCHY ACCESS ▚▚▚▚▚  📌

  /// Путь в иерархии от рута до текущего узла вида:
  /// /App[1]/SomePage[1]/SomeParent[4]/SomeItem[7]
  /// где текст — [_nodeType] указанный в JSON описании дерева,
  /// а цифра в квадратных скобках — порядковый номер [index] объекта
  /// в иерархии его родителя.
  @protected
  String get path => '${_parent?.path}$_nodeType[$index]/';

  /// Количество дочерних узлов
  int get length => _children.length;

  /// Returns `true` if there are no children.
  @protected
  bool get isEmpty => _children.isEmpty;

  /// Returns true if there is at least one child.
  @protected
  bool get isNotEmpty => _children.isNotEmpty;

  /// Позиция текущего узла в списке детей [_parent] узла.
  int get index => _parent?._children.indexOf(this as NodeUx) ?? 0;

  /// Верхний узел текущего дерева.
  @protected
  NodeUx get root => _parent?.root ?? this as NodeUx;

  /// Типизированный доступ к [root]
  @protected
  T getRoot<T extends NodeUx>() => root as T;

  /// Родительский узел
  _NodeUx? _parent;

  /// Узел-адаптор.
  /// Используется при создании отдельных деревьев,
  /// как правило, предназначенных для отдельных страниц.
  /// Нужен для возможности передачи данных в основное
  /// дерево приложения.
  _NodeUx? _adaptor;

  /// Массив дочерних узлов.
  /// В будущем желательно указать подтип вида: List<E extends NodeUx>>
  /// где E — родительский класс для всех дочерних узлов — это еще реализовать надо.
  final List<NodeUx> _children = [];
  List<NodeUx> get children => _children;

  void sort(Comparator compare) => _children.sort(compare);

  /// Получение дочернего узла по ID, указанному в в JSON описании дерева
  @protected
  NodeUx? getChildById(String id) => _idMap.getById(id);

  /// First child node
  @protected
  NodeUx? get firstChild => getChildAt(0);

  /// Is first
  @protected
  bool get isFirst => _parent == null ? true : index == 0;

  /// Is last
  @protected
  bool get isLast => _parent == null ? true : index == ((_parent?.length ?? 0) - 1);

  /// First sibling node
  @protected
  NodeUx get firstSibling => _parent?.getChildAt(0) ?? this as NodeUx;

  /// Last sibling node
  @protected
  NodeUx get lastSibling => _parent?.getChildAt((_parent?.length ?? 0) - 1) ?? this as NodeUx;

  /// Previous sibling node
  @protected
  NodeUx? get prevSibling => _parent?._childBefore(this as NodeUx);

  NodeUx? _childBefore(NodeUx child) {
    int position = indexOf(child) - 1;
    return getChildAt(position);
  }

  /// Next sibling node
  @protected
//  NodeUx? get nextSibling => _parent.getChildAt(_parent.indexOf(this as NodeUx) + 1);
  NodeUx? get nextSibling => _parent!._childAfter(this as NodeUx);

  NodeUx? _childAfter(NodeUx child) {
    int position = indexOf(child) + 1;
    return getChildAt(position);
  }

  /// Следующий зацикленный дочерний узел.
  /// При вызове свойства из последнего узла, возвращается
  /// первый дочерний узел, таким образом, зацикливая список
  @protected
  NodeUx? get nextCycled => nextSibling ?? _parent?.firstChild;

  /// Previous cycled child node
  /// При вызове свойства из первого узла, возвращается
  /// последний дочерний узел, таким образом, зацикливая список.
  @protected
  NodeUx? get prevCycled => prevSibling ?? _parent?.lastChild;

  /// Последний дочерний узел
  @protected
  NodeUx? get lastChild => getChildAt(_children.length - 1);

  /// Дочерний узел в указанной позиции
  @protected
  NodeUx? getChildAt(int index) => (index < 0 || index >= _children.length) ? null : _children[index];

  /// Returns the index of [child] node in children list.
  ///
  /// Searches the children list from index [start] to the end of the list.
  /// The first time an object [child] is encountered so that [child] == element,
  /// the index of element is returned.
  /// Returns -1 if [child] is not found.
  @protected
  int indexOf(NodeUx child, [int start = 0]) => _children.indexOf(child, start);

  /// Получение дочернего узла указанного типа начиная
  /// с позиции [start] в списке дочерних узлов.
  @protected
  T? getTypedChild<T extends NodeUx>([int start = 0]) {
    for (int i = start; i < _children.length; i++) {
      if (_children[i].runtimeType == T) return _children[i] as T;
    }
    return null;
  }

  /// Получение дочернего узла указанного класса [type] начиная
  /// с позиции [start] в списке дочерних узлов.
  @protected
  NodeUx? getChildByType(Type type, [int start = 0]) {
    for (int i = start; i < _children.length; i++) {
      if (_children[i].runtimeType == type) return _children[i];
    }
    return null;
  }

  /// Получение дочернего узла указанного в JSON строкового типа [_nodeType]
  /// начиная с позиции [start] в списке дочерних узлов.
  @protected
  NodeUx? getChildByNodeType(String type, [int start = 0]) {
    for (int i = start; i < _children.length; i++) {
      if (_children[i]._nodeType == type) return _children[i];
    }
    return null;
  }

  //  📌  ▚▚▚▚▚ DESCENDANTS ▚▚▚▚▚  📌

  /// Получение массива дочерних узлов указанного типа [T].
  /// Если тип не указан, то буден возвращен массив всех
  /// дочерних узлов и всех их потомков.
  @protected
  List<T> descendants<T extends NodeUx>() => _collectDescendants();

  List<T> _collectDescendants<T extends NodeUx>([NodeUx? node, List<T>? result]) {
    result = result ?? [];
    if (node == null) {
      node = this as NodeUx;
    } else if (T == NodeUx || node is T) {
      result.add(node as T);
    }
    node._children.forEach((NodeUx child) => _collectDescendants(child, result));
    return result;
  }

  //  📌  ▚▚▚▚▚ ANCESTORS ▚▚▚▚▚  📌

  /// Получение узла в иерархии выше по его классу [T].
  T? getTypedAncestor<T extends NodeUx>() {
    _NodeUx? visitor = _parent;
    while (visitor != null) {
      if (visitor is T) return visitor;
      visitor = visitor._parent;
    }
    return null;
  }

  /// Получение узла в иерархии выше по его классу [type].
  @protected
  NodeUx? getAncestorByType(Type type) => runtimeType == type ? this as NodeUx : _parent?.getAncestorByType(type);

  /// Получение узла в иерархии выше по его [type] — строковому типу, заданному в JSON.
  @protected
  NodeUx? getAncestorByNodeType(String type) => _nodeType == type ? this as NodeUx : _parent?.getAncestorByNodeType(type);

  //  📌  ▚▚▚▚▚ HIERARCHY CONTROL ▚▚▚▚▚  📌

  /// Метод, добавляет дочерним узел в конец списка детей текущего узла.
  /// @param [child] — добавляемый узел
  /// @param [notify] — флаг, определяющий режим перерисовки View.
  /// По умолчанию — true, что значит, что после добавления узла
  /// будет вызван метод отложенной перерисовки экрана (в следующем тике).
  /// @returns <T extends [NodeUx]> — возвращает добавленный узел
  @protected
  T addChild<T extends NodeUx>(T child, {bool notify = true}) {
    return addChildAt(_children.length, child, needsBuild: notify);
  }

  /// Inserts the [child] at position [index] in children list.
  ///
  /// This increases the length of the list by one and shifts all objects
  /// at or after the index towards the end of the list.
  ///
  /// The list must be growable.
  /// The [index] value must be non-negative and no greater than [length].
  ///
  /// Default value of [needsBuild] property is true — a delayed
  /// screen redraw command will be called.
  @protected
  T addChildAt<T extends NodeUx>(int index, T child, {bool needsBuild = true}) {
    _children.insert(index, child);
    child._parent = this;
    child._registerID();
    if (needsBuild) {
      markNeedsBuild();
    }
    return child;
  }

  @protected
  NodeUx remove({bool notify = true}) {
    if (_parent == null) return this as NodeUx;

    final parent = _parent;
    parent?._children.remove(this);
    _parent = null;

    _removeID();
    if (notify) {
      parent?.markNeedsBuild();
    }
    _onRemoved(this as NodeUx);
    return this as NodeUx;
  }

  /// Событие, вызываемое при удалении узла из дерева.
  ///
  /// Вызывается у удаляемого узла и всех его потомков.
  ///
  /// @param [NodeUx] [removedNode] — верхний узел
  /// удаленной ветки узлов.
  ///
  /// @return [void]
  ///
  /// Это событие удобно использовать для предотвращения
  /// memory leaks при удалении узлов из дерева — можно
  /// выключить таймеры, отписаться от внешних событий,
  /// и других зависимостей.
  ///
  /// Не требует вызова super. [onRemoved] ().
  ///
  /// ```dart
  ///   @override
  ///   void onRemoved(NodeUx removedNode) {
  ///     removeListener(someHandler);
  ///     someTimer?.cancel();
  ///   }
  /// ```
  ///
  @protected
  void onRemoved(NodeUx removedNode) {}

  void _onRemoved(NodeUx removedNode) {
    _children.forEach((_NodeUx child) => child._onRemoved(removedNode));
    onRemoved(removedNode);
  }

  @protected
  NodeUx? removeChildAt(int childIndex) => getChildAt(childIndex)?.remove();

  @protected
  List<NodeUx> removeChildren({bool notify = true}) {
    List<NodeUx> removedNodes = [..._children];
    while (isNotEmpty) {
      lastChild?.remove(notify: false);
    }
    if (notify) {
      markNeedsBuild();
    }
    return removedNodes;
  }

  //  📌 ▚▚▚▚▚  OPENED CONTROL  ▚▚▚▚▚  📌

  /// Открытый дочерний узел
  NodeUx? _openedChild;

  /// Возвращает состояние узла открыт/закрыт
  @protected
  bool get isOpened => _parent == null || _parent?.openedChild == this || _parent is NodeUxGroup;

  @protected
  @mustCallSuper
  void open() {
    if (_parent == null) return;
    _parent!.openedChild = this as NodeUx;
  }

  /// Возвращает открытый дочерний узел
  NodeUx? get openedChild {
    if (_children.isEmpty) return null;
    _openedChild ??= _children.first;
    return _openedChild as NodeUx;
  }

  /// Задает открытый дочерний узел
  @protected
  @mustCallSuper
  set openedChild(NodeUx? child) => _setOpenedChild(child);

  void _setOpenedChild(NodeUx? child, {bool notifyListeners = true}) {
    if (_openedChild == child || child == null) return;
    if (_openedChild != null) {
      _openedChild!.onClose();
      _openedChild!._onBranchClose();
      _openedChild!._setProperty(OPENED, _FALSE, notifyListeners: false);
    }
    _openedChild = child;
    child._onBranchOpen();
    child._setProperty(OPENED, _TRUE, notifyListeners: notifyListeners);
  }

  void _onBranchOpen([NodeUx? openedAncestor]) {
    if (!isBranchOpened) return;
    _NodeUx? visitor = openedChild;
    while (visitor != null) {
      visitor.onBranchOpen(openedAncestor ?? this as NodeUx);
      visitor = visitor.openedChild;
    }
  }

  /// Вызывается при открытии ветки (но не себя)
  @protected
  void onBranchOpen(NodeUx openedAncestor) {}

  /// Вызывается при закрытии узла
  @protected
  void onClose() {}

  /// Вызывается при закрытии ветки (но не себя)
  @protected
  void onBranchClose(NodeUx closedAncestor) {}

  /// Вызывается при закрытии ветки (но не себя)
  void _onBranchClose([NodeUx? closedAncestor]) {
    if (!isBranchOpened) return;
    _NodeUx? visitor = openedChild;
    while (visitor != null) {
      visitor.onBranchClose(closedAncestor ?? this as NodeUx);
      visitor = visitor.openedChild;
    }
  }

  /// Возвращает true если узел находится в открытой ветке
  @protected
  bool get isBranchOpened {
    _NodeUx? visitor = _parent;
    while (visitor != null) {
      if (!visitor.isOpened) return false;
      visitor = visitor._parent;
    }
    return true;
  }

  /// Открывает всю ветку от текущего узла вверх до root
  @protected
  void openBranch() {
    if (_parent == null) {
      _setProperty(OPENED, _TRUE, notifyListeners: true);
      return;
    }
    _parent?._setOpenedChild(this as NodeUx, notifyListeners: false);
    _parent?.openBranch();
  }

  /// Получение массива открытых дочерних узлов по иерархии вниз от текущего узла.

  @protected
  List<NodeUx> openedDescendants() {
    final List<NodeUx> result = [];
    NodeUx? visitor = openedChild;
    while (visitor != null) {
      result.add(visitor);
      visitor = visitor.openedChild;
    }
    return result;
  }

  //  📌 ▚▚▚▚▚  OTHER PROPERTIES  ▚▚▚▚▚  📌

  void _setProperty(String name, String value, {bool notifyListeners = true}) {
    _props[name] = value;
    if (notifyListeners || name == OPENED) {
      markNeedsBuild();
    }
  }

  /// Возвращает по имени значение свойства, указанного
  /// в объекте _props текушего узла JSON документа.
  @protected
  String? getProperty(String name) => _props[name];

  /// Глубина узла в иерархии дерева
  @protected
  int get depth => (_parent?.depth ?? -1) + 1;

  /// Возвращает строку символов \t в количестве, соответствующем
  /// глубине [depth] узла в иерархии дерева.
  @protected
  String get tabs => '${(_parent?.tabs ?? '')}\t';

  //  📌 ▚▚▚▚▚  MARK NEEDS BUILD  ▚▚▚▚▚  📌

  /// boolean свойство, указывающее, было ли помечено дерево
  /// для перерисовки.
  bool get dirty => root._dirty;
  bool _dirty = false;

  /// Указание дереву необходимости перерисовки.
  void markNeedsBuild() {
    if (root._blockers.contains(runtimeType)) {
      /// Если хочет обновиться узел, который до этого ставил блокировку,
      /// то автоматом для удаляем соответствующую запись
      root._blockers.remove(runtimeType);
    }
    root._markNeedsBuild();
  }

  void _markNeedsBuild() {
    // проверяем, что никто не просил "заморозить" перерисовку
    if (_blockers.isNotEmpty) {
      return;
    }
    if (dirty) return;
    _dirty = true;
    Future(() {
      _dirty = false;

      final treeUxListener = root._treeUxListener;
      if (treeUxListener != null) {
        treeUxListener();
      }
    });
  }

  BuildContext? _buildContext;

  void clearBuildContext() => _buildContext = null;

  void updateBuildContext(BuildContext context) => _buildContext = context;

  @protected
  BuildContext? get buildContext => _buildContext ?? _parent?.buildContext ?? _adaptor?.buildContext;

  /// Блокировка всех перерисовок
  final Set<Type> _blockers = {};

  /// Из ноды блокируем перерисовки
  ///
  /// Может пригодится, когда на фоне данные обновляются, а текущий виджет завязан на [BuildContext]
  /// Например, в коде есть [Navigator.pop], а на фоне отработал side-effect и выдал новые данные,
  /// после которых надо сделать [_NodeUx.markNeedsBuild]
  void preventReBuild() {
    root._blockers.add(runtimeType);
  }

  //  📌 ▚▚▚▚▚  TO DO  ▚▚▚▚▚  📌

  /// TODO — сделать library тип PAGE
  /// нет, ботва, вроде не так это надо сделать
  @protected
  T? getPage<T extends NodeUx>() {
    if (getProperty(PAGE) != null) {
      if (runtimeType == T) return this as T;
    }
    return _parent?.getPage();
  }
}

//  📌 ▚▚▚▚▚▚▚▚▚▚  NodeUx  ▚▚▚▚▚▚▚▚▚▚  📌

abstract class NodeUx<ParentType extends _NodeUx> extends _NodeUx {
  static const String _TRUE = 'true';

  static final TreeUxLibrary _treeUxLibrary = TreeUxLibrary();

  static late Map<String, NodeUxBuilder> _buildersMap;

  Function? _treeUxListener;

  //  📌 ▚▚▚▚▚  CREATION ▚▚▚▚▚  📌

  /// Создает NodeUx-дерево
  factory NodeUx.createTree(Map<String, dynamic> treeUxMap, Map<String, NodeUxBuilder> buildersMap) {
    _buildersMap = buildersMap;
    _treeUxLibrary.registerLibraryItems(treeUxMap);
    final treeUxRoot = TreeUxRoot(treeUxMap);
    return _createNode(treeUxRoot) as NodeUx<ParentType>;
  }

  /// Создает узел
  static NodeUx<_NodeUx> _createNode(NodeUx parent) {
    Map<String, dynamic>? treeUx = parent._tempMap;
    String builderName = treeUx?[TYPE] ?? 'no builder name';
    final NodeUxBuilder? builder = _buildersMap[builderName];
    if (builder == null) {
      throw ErrorUx('⛔ [NodeUx].NodeUx._createNode([parent]) no builder for $builderName');
    }
    return builder(parent);
  }

  /// Конструктор
  NodeUx(ParentType? parent) {
    if (parent == null || ParentType == _NodeUx) {
      print('⛔ [NodeUx]([data, parent]) \n');
      print('\t\terror:    class $runtimeType<$ParentType>');
      print('\t\texpected: class $runtimeType<${parent.runtimeType}>');
    } else {
      _initInstance(parent._tempMap, parent);
    }
  }

  /// Создает библиотечный элемент
  @protected
  NodeUx.create(String libraryType, {ParentType? parent, ParentType? adaptor}) {
    _initInstance(_treeUxLibrary.getLibraryItem(libraryType), parent).._adaptor = adaptor;
  }

  /// Инициализация экземпляра
  NodeUx<ParentType> _initInstance(Map<String, dynamic>? data, ParentType? parent) {
    parent?.addChild(this);
    if (data == null || data.isEmpty) return this;

    _nodeType = data[TYPE];

    _createProps(data);
    _registerID();
    _createChildren(data);
    if (getProperty(OPENED) == _TRUE) {
      open();
    }
    return this;
  }

  /// Создание дочерних узлов.
  /// В свою очередь, дочерние узлы при инициализации
  /// [_initInstance] создадут свои дочерние узлы.
  void _createChildren(Map<String, dynamic> data) {
    if (data[CHILDREN] == null) return;
    final childrenList = data[CHILDREN] as List<dynamic>;
    childrenList.forEach((dynamic child) {
      _tempMap = child;
      _createNode(this);
    });
    _tempMap = null;
  }

  /// Создание свойств
  void _createProps(Map<String, dynamic> data) {
    data[PROPS]?.forEach((key, value) => _props[key] = value);
  }

  //  📌 ▚▚▚▚▚  SERIALIZATION  ▚▚▚▚▚  📌

  Map<dynamic, dynamic> toMap() {
    Map<dynamic, dynamic> map = {};
    map[TYPE] = _nodeType;
    map[PROPS] = _props;
    map[PROPS][PATH] = path;
    map[PROPS][DEPTH] = depth.toString();
    if (isNotEmpty) {
      map[CHILDREN] = _childrenToList();
    }
    return map;
  }

  List<Map> _childrenToList() {
    final List<Map> result = [];
    for (int i = 0; i < _children.length; i++) {
      result.add(_children[i].toMap());
    }
    return result;
  }

  @override
  String toString() => jsonEncode(toMap());

  void printNode() {
    print('$tabs $depth $_nodeType');
    for (int i = 0; i < _children.length; i++) {
      _children[i].printNode();
    }
  }

  //  📌 ▚▚▚▚▚  HIERARCHY  ▚▚▚▚▚  📌

  @protected
  ParentType? get parent => _parent as ParentType;

  @protected
  ParentType get adaptor => _adaptor as ParentType;

//  📌 ▚▚▚▚▚  EVENTS  ▚▚▚▚▚  📌

  void setTreeUxListener(Function onRedraw) {
    if (this != root) {
      root.setTreeUxListener(onRedraw);
      return;
    }
    _treeUxListener = onRedraw;
  }

  //  📌 ▚▚▚▚▚  VIEW  ▚▚▚▚▚  📌

  ProviderUx get providerUx => ProviderUx(this);

  /// Метод создания View для текущего узла.
  ViewUx createView();

  // Получение View текущего узла
  ViewUx? get openedChildView => openedChild?.createView();
}

class TreeUxRoot extends NodeUx {
  // TreeUxRoot(Map<String, dynamic> data) : super(null) {
  TreeUxRoot(Map<String, dynamic> data) : super(null) {
    _tempMap = data;
    Future(() => _tempMap = null);
  }

  @override
  ViewUx createView() => throw ErrorUx('TreeUxRoot have not view');

  @override
  @protected
  NodeUx get root => _children[0];

  @protected
  @override
  String get path => '/';

  @protected
  @override
  NodeUx get firstSibling => this;

  @protected
  @override
  NodeUx get lastSibling => this;

  @protected
  @override
  NodeUx? get prevSibling => null;

  /// Next sibling node
  @protected
  @override
  NodeUx? get nextSibling => null;

  /// Получение узла в иерархии выше по его классу [T].
  @override
  T? getTypedAncestor<T extends NodeUx>() => this is T ? this as T : null;

  @protected
  @override
  NodeUx? getAncestorByType(Type type) => runtimeType == type ? this as NodeUx : null;

  @protected
  @override
  NodeUx? getAncestorByNodeType(String type) => _nodeType == type ? this as NodeUx : null;

  @protected
  @override
  NodeUx remove({bool notify = true}) {
    return this;
  }
}

abstract class NodeUxGroup<ParentType extends NodeUx> extends NodeUx {
  NodeUxGroup(NodeUx parent) : super(parent);

  @override
  NodeUx? get openedChild => null;

  @override
  void _setOpenedChild(NodeUx? child, {bool notifyListeners = true}) {}

  @override
  void _onBranchOpen([NodeUx? openedAncestor]) {
    if (!isBranchOpened) return;
    onBranchOpen(openedAncestor ?? this);
    for (int i = 0; i < _children.length; i++) {
      _children[i]._onBranchOpen(openedAncestor ?? this);
    }
  }

  /// Вызывается при закрытии ветки (но не себя)
  @override
  @protected
  void onBranchClose(NodeUx closedAncestor) {}

  /// Вызывается при закрытии ветки (но не себя)
  @override
  void _onBranchClose([NodeUx? closedAncestor]) {
    if (!isBranchOpened) return;
    for (int i = 0; i < _children.length; i++) {
      _children[i]._onBranchClose(closedAncestor ?? this);
      _children[i].onBranchClose(closedAncestor ?? this);
    }
  }
}
