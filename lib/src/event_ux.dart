typedef HandlerUx<T extends EventUx> = void Function(T event);

mixin TreeUxEventsMember {
  /// Список всех слушателей, подписанных на какие-либо события дерева.
  static final List<TreeUxEventsMember> _listeners = [];

  /// Каждый экземпляр имеет свою карту "тип события" : "обработчики события"
  final Map<String, Map<HandlerUx, bool>> _eventsMaps = {};

  void dispatchEvent<T extends EventUx>(T event) {
    event._dispatcher = this;
    for (int i = 0; i < _listeners.length; i++) {
      _listeners[i]._dispatch(event);
    }
    event._dispatcher = null;
    event._stopPropagation = false;
  }

  void _dispatch<T extends EventUx>(T event) {
    if (event._stopPropagation) return;
    final handlersMap = _eventsMaps[event.eventType];
    if (handlersMap == null) return;
    event._listener = this;
    handlersMap.forEach((HandlerUx handler, bool value) {
      if (event._stopPropagation) return;
      handler(event);
    });
    event._listener = null;
  }

  void addEventListener(String eventType, HandlerUx handler) {
    removeEventListener(eventType, handler);
    if (_eventsMaps.isEmpty) _listeners.add(this);

    final mapOfEvent = _eventsMaps[eventType];
    if (mapOfEvent == null) _eventsMaps[eventType] = <HandlerUx, bool>{};
    mapOfEvent![handler] = true;
  }

  void removeEventListener(String eventType, HandlerUx handler) {
    final mapOfEvent = _eventsMaps[eventType];
    if (mapOfEvent == null) return;

    mapOfEvent.remove(handler);
    if (mapOfEvent.isEmpty) _eventsMaps.remove(eventType);
    _tryRemoveEventsMaps();
  }

  void removeAllEventListeners() {
    _eventsMaps.forEach((String type, Map value) => _eventsMaps.remove(type));
    _tryRemoveEventsMaps();
  }

  void _tryRemoveEventsMaps() {
    if (_eventsMaps.isEmpty) _listeners.remove(this);
  }
}

class EventUx {
  static const String REDRAW = 'propertyChanged';
  static const String STRUCTURE_CHANGED = 'structureChanged';

  final String eventType;

  bool _stopPropagation = false;
  TreeUxEventsMember? _dispatcher;
  TreeUxEventsMember? _listener;

  TreeUxEventsMember? get dispatcher => _dispatcher;

  TreeUxEventsMember? get listener => _listener;

  EventUx(this.eventType);

  void stopPropagation() => _stopPropagation = true;
}
