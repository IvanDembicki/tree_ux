import 'package:flutter/material.dart';

import 'node_ux.dart';

/// A widget to extend for every node_ux view
/// It is stateless because all state for view is in [NodeUx]
/// So in [ViewUx] you can only show data from [NodeUx] and call node's methods to update state
abstract class ViewUx<T extends NodeUx> extends StatelessWidget {
  @protected
  final T nodeUx;

  ViewUx(this.nodeUx, {Key? key}) : super(key: key);

  Type get nodeUxType => T;
}
