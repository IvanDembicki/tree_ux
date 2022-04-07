import 'package:flutter/material.dart';

import '../tree_ux.dart';

/// Provides a TreeUx Data to all descendants of this Widget. This should
/// generally be a root widget in your App. Connect to the Node Data of Tree provided
/// by this Widget using a [ViewUx] and passing [NodeUx] to view's constructor.
class ProviderUx<T extends NodeUx> extends StatefulWidget {
  final T nodeUx;

  Type get nodeUxType => T;

  ProviderUx(this.nodeUx, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProviderUxState();
}

class _ProviderUxState extends State<ProviderUx> {
  void Function()? redraw;

  @override
  void initState() {
    redraw = () => setState(() {});
    widget.nodeUx.setTreeUxListener(onRedraw);
    super.initState();
  }

  @override
  void dispose() {
    redraw = null;
    widget.nodeUx.clearBuildContext();
    super.dispose();
  }

  void onRedraw() {
    if (redraw != null) {
      print('[_ProviderUxState]<${widget.nodeUx.runtimeType}>.onRedraw() ${DateTime.now()}');
      redraw!();
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.nodeUx.updateBuildContext(context);
    ViewUx viewUx = widget.nodeUx.createView();
    // if (viewUx == null) {
    //   throw ErrorUx('_ProviderUxState: build(...) widget.nodeUx.createView() == null');
    //
    // }
    return HistoryUx(child: viewUx);
  }
}
