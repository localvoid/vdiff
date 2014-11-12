// Copyright (c) 2014, the VDiff project authors. Please see the AUTHORS file for
// details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vdiff;

/// Virtual Dom Element
class Element extends Node {
  /// [Element] tag name
  final String tag;

  /// [Element] attributes
  Map<String, String> attributes;

  /// [Element] styles
  Map<String, String> styles;

  /// Element classes
  List<String> classes;

  /// Element children
  List<Node> children;

  /// Create a new [Element]
  Element(Object key, this.tag, this.children,
      {this.attributes: null,
       this.classes: null,
       this.styles: null})
      : super(key);

  Element build(Context context) {
    final newChildren = [];
    for (var i = 0; i < children.length; i++) {
      newChildren.add(children[i].build(context));
    }
    return new Element(key, tag, newChildren,
        attributes: attributes,
        classes: classes,
        styles: styles);
  }

  /// Run diff against [other] [Element] and return [ElementPatch] or [null] if
  /// nothing is changed
  ElementPatch diff(Element other, Context context) {
    var attributesPatch;
    var stylesPatch;
    var classesPatch;

    if (attributes != null || other.attributes != null) {
      attributesPatch = mapDiff(attributes, other.attributes);
    }
    if (styles != null || other.styles != null) {
      stylesPatch = mapDiff(styles, other.styles);
    }
    if (classes != null || other.classes != null) {
      classesPatch = unorderedListDiff(classes, other.classes);
    }
    final childrenPatch = diffChildren(children, other.children, context);

    if (attributesPatch == null &&
        stylesPatch == null &&
        classesPatch == null &&
        childrenPatch == null) {
      return null;
    }

    return new ElementPatch(
        attributesPatch,
        stylesPatch,
        classesPatch,
        childrenPatch);
  }

  /// Render [Element] and return [html.Element]
  html.Element render() {
    final ref = html.document.createElement(tag);
    if (attributes != null) {
      attributes.forEach((key, value) {
        ref.setAttribute(key, value);
      });
    }
    if (styles != null) {
      styles.forEach((key, value) {
        ref.style.setProperty(key, value);
      });
    }
    if (classes != null) {
      ref.classes.addAll(classes);
    }

    for (var i = 0; i < children.length; i++) {
      ref.append(children[i].render());
    }

    return ref;
  }

  String toString() => '<$tag key="$key">${children.join()}</$tag>';
}

ElementChildrenPatch diffChildren(List<Node> a, List<Node> b, Context context) {
  if (a.isNotEmpty) {
    if (b.isEmpty) {
      // when [b] is empty, it means that all childrens from list [a] were
      // removed
      final removedPositions = new List(a.length);
      for (var i = 0; i < a.length; i++) {
        removedPositions[i] = i;
      }
      return new ElementChildrenPatch(
          removedPositions, null, null, null, null, null);

    } else {
      if (a.length == 1 && b.length == 1) {
        // fast path when [a] and [b] have just 1 child
        //
        // if both lists have child with the same key, then just diff them,
        // otherwise return patch with [a] child removed and [b] child inserted
        final aNode = a.first;
        final bNode = b.first;

        if (aNode.key == bNode.key) {
          var modified = aNode.diff(bNode, context);

          if (modified != null) {
            return new ElementChildrenPatch(
                null, null, null, null, [modified], [0]);
          }
          return null;
        }

        return new ElementChildrenPatch(
            [0], null, [bNode.build(context)], [0], null, null);

      } else if (a.length == 1) {
        // fast path when [a] have 1 child

        final aNode = a.first;
        final insertedNodes = new List();
        final insertedPositions = new List();
        var removedPositions;
        var modifiedNodes;
        var modifiedPositions;

        // [a] child position
        // if it is -1, then the child is removed
        var unchangedPosition = -1;

        for (var i = 0; i < b.length; i++) {
          final bNode = b[i];
          if (aNode.key == bNode.key) {
            unchangedPosition = i;
            break;
          } else {
            insertedNodes.add(bNode.build(context));
            insertedPositions.add(0);
          }
        }

        if (unchangedPosition != -1) {
          for (var i = unchangedPosition + 1; i < b.length; i++) {
            insertedNodes.add(b[i].build(context));
            insertedPositions.add(1);
          }
          final patch = aNode.diff(b[unchangedPosition], context);
          if (patch != null) {
            modifiedNodes = [patch];
            modifiedPositions = [0];
          }
        } else {
          removedPositions = [0];
        }

        return new ElementChildrenPatch(
            removedPositions,
            null,
            insertedNodes,
            insertedPositions,
            modifiedNodes,
            modifiedPositions);
      } else if (b.length == 1) {
        // fast path when [b] have 1 child

        final bNode = b.first;
        final removedPositions = new List();
        var insertedNodes;
        var insertedPositions;
        var modifiedNodes;
        var modifiedPositions;

        // [a] child position
        // if it is -1, then the child is inserted
        var unchangedPosition = -1;

        for (var i = 0; i < a.length; i++) {
          final aNode = a[i];
          if (aNode.key == bNode.key) {
            unchangedPosition = i;
            break;
          } else {
            removedPositions.add(i);
          }
        }

        if (unchangedPosition != -1) {
          for (var i = unchangedPosition + 1; i < a.length; i++) {
            removedPositions.add(i);
          }
          final patch = a[unchangedPosition].diff(bNode, context);
          if (patch != null) {
            modifiedNodes = [patch];
            modifiedPositions = [0];
          }
        } else {
          insertedNodes = [bNode.build(context)];
          insertedPositions = [0];
        }

        return new ElementChildrenPatch(
            removedPositions,
            null,
            insertedNodes,
            insertedPositions,
            modifiedNodes,
            modifiedPositions);

      } else {
        // both [a] and [b] have more than 1 child, so we should handle
        // more complex situations with inserting/removing and repositioning
        // childrens
        return _diffChildren2(a, b, context);
      }
    }
  } else if (b.length > 0) {
    // all childrens from list [b] were inserted
    final insertedNodes = new List(b.length);
    final insertedPositions = new List(b.length);
    for (var i = 0; i < b.length; i++) {
      insertedNodes[i] = b[i].build(context);
      insertedPositions[i] = 0;
    }
    return new ElementChildrenPatch(
        null,
        null,
        insertedNodes,
        insertedPositions,
        null,
        null);
  }

  return null;
}

ElementChildrenPatch _diffChildren2(List<Node> a, List<Node> b,
                                    Context context) {
  final modifiedPositions = [];
  final modifiedNodes = [];
  var changesCounter = 0;
  var aLength = a.length;
  var bLength = b.length;

  final minLength = aLength < bLength ? aLength : bLength;

  var start = 0;
  while(start < minLength) {
    final aNode = a[start];
    final bNode = b[start];
    if (aNode.key != bNode.key) {
      break;
    }
    final patch = aNode.diff(bNode, context);
    if (patch != null) {
      modifiedPositions.add(start);
      modifiedNodes.add(patch);
      changesCounter++;
    }
    start++;
  }

  if (start == bLength) {
    if (start == aLength) {
      if (changesCounter == 0) {
        return null;
      }
      return new ElementChildrenPatch(
          null,
          null,
          null,
          null,
          modifiedNodes,
          modifiedPositions);
    } else {
      final removedPositions = new List();
      for (var i = start; i < a.length; i++) {
        removedPositions.add(i);
      }
      return new ElementChildrenPatch(
          removedPositions,
          null,
          null,
          null,
          modifiedNodes.isEmpty ? null : modifiedNodes,
          modifiedPositions.isEmpty ? null : modifiedPositions);
    }
  } else if (start == aLength) {
    final insertedNodes = new List();
    final insertedPositions = new List();
    for (var i = start; i < b.length; i++) {
      insertedNodes.add(b[i]);
      insertedPositions.add(start);
    }
    return new ElementChildrenPatch(
        null,
        null,
        insertedNodes,
        insertedPositions,
        modifiedNodes.isEmpty ? null : modifiedNodes,
        modifiedPositions.isEmpty ? null : modifiedPositions);
  }

  var aEnd = a.length - 1;
  var bEnd = b.length - 1;
  while (aEnd >= start && bEnd >= start) {
    final aNode = a[aEnd];
    final bNode = b[bEnd];

    if (aNode.key != bNode.key) {
      break;
    }
    final patch = aNode.diff(bNode, context);
    if (patch != null) {
      modifiedPositions.add(aEnd);
      modifiedNodes.add(aNode);
      changesCounter++;
    }
    aEnd--;
    bEnd--;
  }
  aEnd++;
  bEnd++;

  if (aEnd == start) {
    assert(bEnd != start);
    final insertedNodes = new List();
    final insertedPositions = new List();
    for (var i = start; i < bEnd; i++) {
      insertedNodes.add(b[i]);
      insertedPositions.add(aEnd);
    }
    return new ElementChildrenPatch(
        null,
        null,
        insertedNodes,
        insertedPositions,
        modifiedNodes.isEmpty ? null : modifiedNodes,
        modifiedPositions.isEmpty ? null : modifiedPositions);
  } else if (bEnd == start) {
    final removedPositions = new List();
    for (var i = start; i < aEnd; i++) {
      removedPositions.add(i);
    }
    return new ElementChildrenPatch(
        removedPositions,
        null,
        null,
        null,
        modifiedNodes.isEmpty ? null : modifiedNodes,
        modifiedPositions.isEmpty ? null : modifiedPositions);
  } else {
    aLength = aEnd - start;
    bLength = bEnd - start;

    final removedPositions = new List<int>();
    final insertedNodes = new List<Node>();
    final insertedPositions = new List<int>();

    final sources = new List<int>.filled(bLength, -1);

    var moved = false;

    // when both lists are small, the join operation is much faster with simple
    // MxN list search instead of hashmap join
    if (aLength * bLength <= 16) {
      var lastTarget = 0;
      var removeOffset = 0;

      for (var i = 0; i < aLength; i++) {
        final iOff = i + start;
        final aNode = a[iOff];
        var removed = true;

        for (var j = 0; j < bLength; j++) {
          final jOff = j + start;
          final bNode = b[jOff];
          if (aNode.key == bNode.key) {
            sources[j] = i - removeOffset;

            // check if items in wrong order
            if (lastTarget > j) {
              moved = true;
            } else {
              lastTarget = j;
            }

            final patch = aNode.diff(bNode, context);
            if (patch != null) {
              modifiedNodes.add(patch);
              modifiedPositions.add(iOff - removeOffset);
              changesCounter++;
            }

            removed = false;
            break;
          }
        }

        if (removed) {
          removedPositions.add(iOff);
          removeOffset++;
          changesCounter++;
        }
      }

    } else {
      final keyIndex = new HashMap<Object, int>();
      var lastTarget = 0;
      var removeOffset = 0;

      // index nodes from list [b]
      for (var i = 0; i < bLength; i++) {
        final node = b[i + start];
        keyIndex[node.key] = i;
      }

      // index nodes from list [a] and check if they're removed
      for (var i = 0; i < aLength; i++) {
        final iOff = i + start;
        final aNode = a[iOff];
        final j = keyIndex[aNode.key];
        if (j != null) {
          final jOff = j + start;
          final bNode = b[jOff];
          sources[j] = i - removeOffset;

          // check if items in wrong order
          if (lastTarget > j) {
            moved = true;
          } else {
            lastTarget = j;
          }

          final patch = aNode.diff(bNode, context);
          if (patch != null) {
            modifiedNodes.add(patch);
            modifiedPositions.add(iOff - removeOffset);
            changesCounter++;
          }
        } else {
          removedPositions.add(iOff);
          removeOffset++;
          changesCounter++;
        }
      }
    }

    var movedPositions;
    // new length without removed nodes
    final newLength = aLength - removedPositions.length;

    if (moved) {
      // create new list without removed/inserted nodes
      // and use source position ids instead of vnodes
      final c = new List<int>.filled(newLength, 0);

      // fill new lists and find all inserted/unchanged nodes
      var insertedOffset = 0;
      for (var i = 0; i < bLength; i++) {
        final node = b[i + start];
        if (sources[i] == -1) {
          insertedNodes.add(node);
          final pos = i - insertedOffset;
          insertedPositions.add(pos >= newLength ? a.length : pos + start);
          insertedOffset++;
          changesCounter++;
        } else {
          c[i - insertedOffset] = sources[i];
        }
      }

      final seq = _lis(c);

      movedPositions = [];
      var i = c.length - 1;
      var j = seq.length - 1;

      while (i >= 0) {
        if (j < 0 || i != seq[j]) {
          final ix = i + 1;
          var t;
          if (ix == c.length) {
            t = ix + start;
          } else {
            t = c[ix] + start;
          }
          movedPositions.add(c[i] + start);
          movedPositions.add(t);
        } else {
          j--;
        }
        i--;
      }

      changesCounter += movedPositions.length;
    } else {
      var insertedOffset = 0;
      for (var i = 0; i < bLength; i++) {
        if (sources[i] == -1) {
          final node = b[i + start];
          insertedNodes.add(node);
          final pos = i - insertedOffset;
          insertedPositions.add(pos + start);
          changesCounter++;
          insertedOffset++;
        }
      }
    }

    if (changesCounter == 0) {
      return null;
    }

    return new ElementChildrenPatch(
        removedPositions.isEmpty ? null : removedPositions,
        movedPositions,
        insertedNodes.isEmpty ? null : insertedNodes,
        insertedPositions.isEmpty ? null : insertedPositions,
        modifiedNodes.isEmpty ? null : modifiedNodes,
        modifiedPositions.isEmpty ? null : modifiedPositions);
  }}

/// Algorithm that finds longest increasing subsequence.
List<int> _lis(List<int> a) {
  List<int> p = new List<int>.from(a);
  List<int> result = new List<int>();

  result.add(0);

  for (var i = 0; i < a.length; i++) {
    if (a[result.last] < a[i]) {
      p[i] = result.last;
      result.add(i);
      continue;
    }

    var u = 0;
    var v = result.length - 1;
    while (u < v) {
      int c = (u + v) ~/ 2;

      if (a[result[c]] < a[i]) {
        u = c + 1;
      } else {
        v = c;
      }
    }

    if (a[i] < a[result[u]]) {
      if (u > 0) {
        p[i] = result[u - 1];
      }

      result[u] = i;
    }
  }
  var u = result.length;
  var v = result.last;

  while (u-- > 0) {
    result[u] = v;
    v = p[v];
  }

  return result;
}
