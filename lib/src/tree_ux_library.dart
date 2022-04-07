import 'dart:convert';

import 'constants_ux.dart';

class TreeUxLibrary {
  final Map<String, String> _library = {};

  TreeUxLibrary();

  void registerLibraryItems(Map<String, dynamic> mapWithoutLazy) {
    final List<dynamic>? children = mapWithoutLazy[CHILDREN] as List<dynamic>?;
    if (children == null || children.isEmpty) return;
    for (int i = 0; i < children.length; i++) {
      final Map<String, dynamic> child = children[i];

      /// children first. Otherwise, if the node is removed ahead of time and added to the library,
      /// then the child objects will not get to the library.
      registerLibraryItems(child);
      final Map<String, dynamic> propsMap = child[PROPS] ?? {};
      if (isLibraryItem(propsMap)) {
        propsMap.remove(LIBRARY);
        propsMap.remove(PAGE);
        if (propsMap.isEmpty) {
          child.remove(PROPS);
        }
        _library[child[TYPE]] = jsonEncode(child);
        children.removeAt(i--);
      }
    }
  }

  bool isLibraryItem(Map<String, dynamic>? propsMap) {
    if (propsMap == null) return false;
    if (propsMap.containsKey(LIBRARY) && propsMap[LIBRARY] == 'true') return true;
    if (propsMap.containsKey(PAGE) && propsMap[PAGE] == 'true') return true;
    return false;
  }

  Map<String, dynamic> getLibraryItem(String libraryType) {
    final String? itemString = _library[libraryType];

    Map<String, dynamic> result = {};
    try {
      if (itemString != null) {
        result = jsonDecode(itemString);
      }
    } catch (error) {
      print('⛔ [TreeUxLibrary].getLibraryItem([$libraryType]) \n\t\terror: $error');
    }
    return result;
  }

  void printMap() {
    List<String> result = [];
    _library.forEach((String name, String value) => result.add(name));
    result.sort();
    print('\t 📚 TreeUxLibrary: 📚');
    print('\t\t${result.join('\n\t\t')}');
    print('\t 📚');
  }
}
