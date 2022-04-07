import 'node_ux.dart';

class NodeUxIdMap {
  final Map<String, NodeUx> _idMap = {};

  NodeUxIdMap();

  void removeID(String id) {
    _idMap.remove(id);
  }

  void registerID(NodeUx node, String id) {
    if (id.isEmpty) return;
    final registeredNode = _idMap[id];
    if (registeredNode != null) {
      print(
          '***ERROR*** [NodeUxIdMap].registerID([$id]) \n\t\terror: id is not unique');
    }
    _idMap[id] = node;
  }

  NodeUx? getById(String id) => _idMap[id];
}
