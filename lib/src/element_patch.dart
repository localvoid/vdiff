// Copyright (c) 2014, the VDiff project authors. Please see the AUTHORS file for
// details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vdiff;

/// [ElementPatch]
class ElementPatch extends NodePatch {
  final MapPatch attributesPatch;
  final MapPatch stylesPatch;
  final UnorderedListPatch classListPatch;
  final ElementChildrenPatch childrenPatch;

  ElementPatch(this.attributesPatch, this.stylesPatch, this.classListPatch,
      this.childrenPatch);

  void apply(html.Element node) {
    if (attributesPatch != null) {
      _applyAttributesPatch(attributesPatch, node);
    }
    if (classListPatch != null) {
      _applyClassListPatch(classListPatch, node);
    }
    if (stylesPatch != null) {
      _applyStylesPatch(stylesPatch, node);
    }
    if (childrenPatch != null) {
      applyChildrenPatch(childrenPatch, node);
    }
  }
}

/// [ElementChildrenPatch] contains modifications to the childNodes list.
///
/// [ElementChildrenPatch] should be applied in the following order:
class ElementChildrenPatch {
  final List<int> removedPositions;
  final List<int> movedPositions;
  final List<Node> insertedNodes;
  final List<int> insertedPositions;
  final List<NodePatch> modifiedNodes; // TODO: rename to modifiedPatches?
  final List<int> modifiedPositions;

  ElementChildrenPatch(this.removedPositions, this.movedPositions,
      this.insertedNodes, this.insertedPositions, this.modifiedNodes,
      this.modifiedPositions);
}

void _applyAttributesPatch(MapPatch patch, html.Element node) {
  final keys = patch.keys;
  final values = patch.values;

  for (var i = 0; i < keys.length; i++) {
    final k = keys[i];
    final v = values[i];
    node.setAttribute(k, v == null ? '' : v);
  }
}

void _applyStylesPatch(MapPatch patch, html.Element node) {
  final keys = patch.keys;
  final values = patch.values;
  final style = node.style;

  for (var i = 0; i < keys.length; i++) {
    final k = keys[i];
    final v = values[i];
    if (v == null) {
      style.removeProperty(k);
    } else {
      style.setProperty(k, v);
    }
  }
}

void _applyClassListPatch(UnorderedListPatch patch, html.Element node) {
  final classes = node.classes;
  if (patch.removed != null) {
    classes.removeAll(patch.removed);
  }
  if (patch.inserted != null) {
    classes.addAll(patch.inserted);
  }
}

void applyChildrenPatch(ElementChildrenPatch patch, html.Node node) {
  final children = node.childNodes;
  final removedPositions = patch.removedPositions;
  final movedPositions = patch.movedPositions;
  final insertedNodes = patch.insertedNodes;
  final insertedPositions = patch.insertedPositions;
  final modifiedNodes = patch.modifiedNodes;
  final modifiedPositions = patch.modifiedPositions;

  if (removedPositions != null) {
    if (removedPositions.length == children.length) {
      var c = children.first;
      while (c != null) {
        final next = c.nextNode;
        c.remove();
        c = next;
      }
    } else {
      final cached = removedPositions.length > 1 ? new List.from(children) : children;
      for (var i = 0; i < removedPositions.length; i++) {
        cached[removedPositions[i]].remove();
      }
    }
  }

  if (modifiedPositions != null || movedPositions != null) {
    var isCached = false;
    var cached = children;
    if (modifiedPositions != null && modifiedPositions.length > 16) {
      cached = new List.from(children);
      isCached = true;
    }
    final cachedLength = cached.length;

    if (modifiedPositions != null) {
      for (var i = 0; i < modifiedPositions.length; i++) {
        final vNode = modifiedNodes[i];
        final node = cached[modifiedPositions[i]];
        vNode.apply(node);
      }
    }

    if (movedPositions != null) {
      final moveOperationsCount = movedPositions.length >> 1;
      if (moveOperationsCount > 16 && !isCached) {
        cached = new List.from(children);
        for (var i = 0; i < moveOperationsCount; i++) {
          final offset = i << 1;
          final source = cached[movedPositions[offset]];
          final p = movedPositions[offset + 1];
          final target = p < cachedLength ? cached[p] : null;
          node.insertBefore(source, target);
        }
      } else {
        final sources = new List(moveOperationsCount);
        final targets = new List(moveOperationsCount);
        for (var i = 0; i < moveOperationsCount; i++) {
          final offset = i << 1;
          final source = cached[movedPositions[offset]];
          final p = movedPositions[offset + 1];
          final target = p < cachedLength ? cached[p] : null;
          sources[i] = source;
          targets[i] = target;
        }
        for (var i = 0; i < moveOperationsCount; i++) {
          node.insertBefore(sources[i], targets[i]);
        }
      }
    }
  }

  if (insertedPositions != null) {
    if (children.length == 0) {
      for (var i = 0; i < insertedPositions.length; i++) {
        final newNode = insertedNodes[i];
        node.append(newNode.render());
      }
    } else {
      final cachedLength = children.length;
      final insertedPositionsCached = new List(insertedPositions.length);
      for (var i = 0; i < insertedPositions.length; i++) {
        final p = insertedPositions[i];
        insertedPositionsCached[i] = p < cachedLength ? children[p] : null;
      }
      for (var i = 0; i < insertedPositions.length; i++) {
        final newNode = insertedNodes[i];
        final e = newNode.render();
        node.insertBefore(e, insertedPositionsCached[i]);
      }
    }
  }
}
