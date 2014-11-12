// Copyright (c) 2014, the VDiff project authors. Please see the AUTHORS file for
// details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vdiff;

/// Abstract [Node] class
abstract class Node {
  /// Key is used in matching algorithm to identify node positions in children
  /// lists.
  ///
  /// Key should be unique among its siblings.
  final Object key;

  Node(this.key);

  /// Render contents
  html.Node render();

  Node build(Context context) => this;

  NodePatch diff(Node other, Context context);
}
