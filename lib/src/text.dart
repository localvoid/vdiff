// Copyright (c) 2014, the VDiff project authors. Please see the AUTHORS file for
// details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vdiff;

class Text extends Node {
  String data;

  Text(Object key, this.data) : super(key);

  html.Text render() {
    return new html.Text(data);
  }

  TextPatch diff(Text other, Context context) {
    if (data != other.data) {
      return new TextPatch(other.data);
    }
    return null;
  }

  String toString() => '$data';
}
