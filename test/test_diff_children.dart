import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:vdiff/vdiff.dart' as v;

v.Element e(Object key, [Object c = const []]) {
  List children;
  if (c is String) {
    children = [new v.Text(0, c)];
  } else {
    children = c;
  }

  return new v.Element(key, 'div', children);
}

/// Generate list of VElements from simple integers.
///
/// For example, list `[0, 1, [2, [0, 1, 2]], 3]` will create
/// list with 4 VElements and the 2nd element will have key `2` and 3 childrens
/// of its own.
List<v.Element> gen(List items) {
  final result = [];
  for (var i in items) {
    if (i is List) {
      result.add(e(i[0], gen(i[1])));
    } else {
      result.add(e('text_$i', i.toString()));
    }
  }
  return result;
}

void checkSync(v.Element a, v.Element b) {
  final ae = a.render();
  final be = b.render();
  final p = a.diff(b, null);
  if (p != null) {
    p.apply(ae);
  }
  final bHtml = be.innerHtml;
  final aHtml = ae.innerHtml;

  if (aHtml != bHtml) {
    throw new TestFailure('Expected: "$bHtml" Actual: "$aHtml"');
  }
}

void main() {
  useHtmlEnhancedConfiguration();

  group('Sync children', () {
    group('No modifications', () {
      test('No childrens', () {
        final a = e(0);
        final b = e(1);
        checkSync(a, b);
      });

      test('Same child', () {
        final a = e(0, gen([0]));
        final b = e(1, gen([0]));
        checkSync(a, b);
      });

      test('Same children', () {
        final a = e(0, gen([0, 1, 2]));
        final b = e(1, gen([0, 1, 2]));
        checkSync(a, b);
      });
    });

    group('Basic inserts', () {
      group('Into empty list', () {
        final a = e(0, []);

        final tests = [{
            'name': 'One item',
            'b': [1]
          }, {
            'name': 'Two items',
            'b': [4, 9]
          }, {
            'name': 'Five items',
            'b': [9, 3, 6, 1, 0]
          }];

        for (var t in tests) {
          final testFn = t['solo'] == true ? solo_test : test;
          final name = t['name'] == null ? '[] => ${t['b']}' : t['name'];

          testFn(name, () {
            final b = e(0, gen(t['b']));
            checkSync(a, b);
          });
        }
      });

      group('Into one element list', () {
        final a = e(0, gen([999]));

        final tests = [{
            'b': [1]
          }, {
            'b': [1, 999]
          }, {
            'b': [999, 1]
          }, {
            'b': [4, 9, 999]
          }, {
            'b': [999, 4, 9]
          }, {
            'b': [9, 3, 6, 1, 0, 999]
          }, {
            'b': [999, 9, 3, 6, 1, 0]
          }, {
            'b': [0, 999, 1]
          }, {
            'b': [0, 3, 999, 1, 4]
          }, {
            'b': [0, 999, 1, 4, 5]
          }];

        for (var t in tests) {
          final testFn = t['solo'] == true ? solo_test : test;
          final name = t['name'] == null ? '[999] => ${t['b']}' : t['name'];

          testFn(name, () {
            final b = e(0, gen(t['b']));

            checkSync(a, b);
          });
        }
      });

      group('Into two elements list', () {
        final a = e(0, gen([998, 999]));

        final tests = [{
            'b': [1, 998, 999]
          }, {
            'b': [998, 999, 1]
          }, {
            'b': [998, 1, 999]
          }, {
            'b': [1, 2, 998, 999]
          }, {
            'b': [998, 999, 1, 2]
          }, {
            'b': [1, 998, 999, 2]
          }, {
            'b': [1, 998, 2, 999, 3]
          }, {
            'b': [1, 4, 998, 2, 5, 999, 3, 6]
          }, {
            'b': [1, 998, 2, 999]
          }, {
            'b': [998, 1, 999, 2]
          }, {
            'b': [1, 2, 998, 3, 4, 999]
          }, {
            'b': [998, 1, 2, 999, 3, 4]
          }, {
            'b': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 998, 999]
          }, {
            'b': [998, 999, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
          }, {
            'b': [0, 1, 2, 3, 4, 998, 999, 5, 6, 7, 8, 9]
          }, {
            'b': [0, 1, 2, 998, 3, 4, 5, 6, 999, 7, 8, 9]
          }, {
            'b': [0, 1, 2, 3, 4, 998, 5, 6, 7, 8, 9, 999]
          }, {
            'b': [998, 0, 1, 2, 3, 4, 999, 5, 6, 7, 8, 9]
          }];

        for (var t in tests) {
          final testFn = t['solo'] == true ? solo_test : test;
          final name = t['name'] == null ? '[998, 999] => ${t['b']}' : t['name'];

          testFn(name, () {
            final b = e(0, gen(t['b']));
            checkSync(a, b);
          });
        }
      });
    });

    group('Basic removes', () {
      group('1 item', () {
        final tests = [{
            'a': [1],
            'b': []
          }, {
            'a': [1, 2],
            'b': [2]
          }, {
            'a': [1, 2],
            'b': [1]
          }, {
            'a': [1, 2, 3],
            'b': [2, 3]
          }, {
            'a': [1, 2, 3],
            'b': [1, 2]
          }, {
            'a': [1, 2, 3],
            'b': [1, 3]
          }, {
            'a': [1, 2, 3, 4, 5],
            'b': [2, 3, 4, 5]
          }, {
            'a': [1, 2, 3, 4, 5],
            'b': [1, 2, 3, 4]
          }, {
            'a': [1, 2, 3, 4, 5],
            'b': [1, 2, 4, 5]
          }];

        for (var t in tests) {
          final testFn = t['solo'] == true ? solo_test : test;
          final name = t['name'] == null ? '${t['a']} => ${t['b']}' : t['name'];

          testFn(name, () {
            final a = e(0, gen(t['a']));
            final b = e(0, gen(t['b']));
            checkSync(a, b);
          });
        }
      });

      group('2 items', () {
        final tests = [{
            'a': [1, 2],
            'b': []
          }, {
            'a': [1, 2, 3],
            'b': [3]
          }, {
            'a': [1, 2, 3],
            'b': [1]
          }, {
            'a': [1, 2, 3, 4],
            'b': [3, 4]
          }, {
            'a': [1, 2, 3, 4],
            'b': [1, 2]
          }, {
            'a': [1, 2, 3, 4],
            'b': [1, 4]
          }, {
            'a': [1, 2, 3, 4, 5, 6],
            'b': [2, 3, 4, 5]
          }, {
            'a': [1, 2, 3, 4, 5, 6],
            'b': [2, 3, 5, 6]
          }, {
            'a': [1, 2, 3, 4, 5, 6],
            'b': [1, 2, 3, 5]
          }, {
            'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            'b': [2, 3, 4, 5, 6, 7, 8, 9]
          }, {
            'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            'b': [0, 1, 2, 3, 4, 5, 6, 7]
          }, {
            'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            'b': [1, 2, 3, 4, 6, 7, 8, 9]
          }, {
            'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            'b': [0, 1, 2, 3, 4, 6, 7, 8]
          }, {
            'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            'b': [0, 1, 2, 4, 6, 7, 8, 9]
          }];

        for (var t in tests) {
          final testFn = t['solo'] == true ? solo_test : test;
          final name = t['name'] == null ? '${t['a']} => ${t['b']}' : t['name'];

          testFn(name, () {
            final a = e(0, gen(t['a']));
            final b = e(0, gen(t['b']));
            checkSync(a, b);
          });
        }
      });
    });

    group('Basic moves', () {
      final tests = [{
          'a': [0, 1],
          'b': [1, 0]
        }, {
          'a': [0, 1, 2, 3],
          'b': [3, 2, 1, 0],
//          'solo': true
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [1, 2, 3, 4, 0]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [4, 0, 1, 2, 3]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [1, 0, 2, 3, 4]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [2, 0, 1, 3, 4]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [0, 1, 4, 2, 3]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [0, 1, 3, 4, 2]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [0, 1, 3, 2, 4]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6],
          'b': [2, 1, 0, 3, 4, 5, 6]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6],
          'b': [0, 3, 4, 1, 2, 5, 6]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6],
          'b': [0, 2, 3, 5, 6, 1, 4]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6],
          'b': [0, 1, 5, 3, 2, 4, 6]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
          'b': [8, 1, 3, 4, 5, 6, 0, 7, 2, 9]
        }, {
          'a': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
          'b': [9, 5, 0, 7, 1, 2, 3, 4, 6, 8]
        }];

      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });

    group('Insert and Move', () {
      final tests = [{
          'a': [0, 1],
          'b': [2, 1, 0],
//          'solo': true
        }, {
          'a': [0, 1],
          'b': [1, 0, 2]
        }, {
          'a': [0, 1, 2],
          'b': [3, 0, 2, 1]
        }, {
          'a': [0, 1, 2],
          'b': [0, 2, 1, 3]
        }, {
          'a': [0, 1, 2],
          'b': [0, 2, 3, 1],
//          'solo': true
        }, {
          'a': [0, 1, 2],
          'b': [1, 2, 3, 0]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [5, 4, 3, 2, 1, 0]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [5, 4, 3, 6, 2, 1, 0]
        }, {
          'a': [0, 1, 2, 3, 4],
          'b': [5, 4, 3, 6, 2, 1, 0, 7]
        }];
      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });

    group('Remove and Move', () {
      final tests = [{
          'a': [0, 1, 2],
          'b': [1, 0]
        }, {
          'a': [2, 0, 1],
          'b': [1, 0]
        }, {
          'a': [7, 0, 1, 8, 2, 3, 4, 5, 9],
          'b': [7, 5, 4, 8, 3, 2, 1, 0]
        }, {
          'a': [7, 0, 1, 8, 2, 3, 4, 5, 9],
          'b': [5, 4, 8, 3, 2, 1, 0, 9]
        }, {
          'a': [7, 0, 1, 8, 2, 3, 4, 5, 9],
          'b': [7, 5, 4, 3, 2, 1, 0, 9]
        }, {
          'a': [7, 0, 1, 8, 2, 3, 4, 5, 9],
          'b': [5, 4, 3, 2, 1, 0, 9]
        }, {
          'a': [7, 0, 1, 8, 2, 3, 4, 5, 9],
          'b': [5, 4, 3, 2, 1, 0]
        }];

      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });

    group('Insert and Remove', () {
      final tests = [{
          'a': [0],
          'b': [1]
        }, {
          'a': [0],
          'b': [1, 2]
        }, {
          'a': [0, 2],
          'b': [1]
        }, {
          'a': [0, 2],
          'b': [1, 2]
        }, {
          'a': [0, 2],
          'b': [2, 1]
        }, {
          'a': [0, 1, 2],
          'b': [3, 4, 5]
        }, {
          'a': [0, 1, 2],
          'b': [2, 4, 5]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 7, 8, 9, 10, 11]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 1, 7, 3, 4, 8]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 7, 3, 8]
        }];

      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });

    group('Insert, Remove and Move', () {
      final tests = [{
          'a': [0, 1, 2],
          'b': [3, 2, 1]
        }, {
          'a': [0, 1, 2],
          'b': [2, 1, 3]
        }, {
          'a': [1, 2, 0],
          'b': [2, 1, 3]
        }, {
          'a': [1, 2, 0],
          'b': [3, 2, 1]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 1, 3, 2, 4, 7]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 1, 7, 3, 2, 4]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, 7, 3, 2, 4]
        }, {
          'a': [0, 2, 3, 4, 5],
          'b': [6, 1, 7, 3, 2, 4]
        }];
      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });

    group('Modified children', () {
      final tests = [{
          'a': [[0, [0]]],
          'b': [0]
        }, {
          'a': [0, 1, [2, [0]]],
          'b': [2]
        }, {
          'a': [0],
          'b': [1, 2, [0, [0]]]
        }, {
          'a': [0, [1, [0, 1]], 2],
          'b': [3, 2, [1, [1, 0]]]
        }, {
          'a': [0, [1, [0, 1]], 2],
          'b': [2, [1, [1, 0]], 3]
        }, {
          'a': [[1, [0, 1]], [2, [0, 1]], 0],
          'b': [[2, [1, 0]], [1, [1, 0]], 3]
        }, {
          'a': [[1, [0, 1]], 2, 0],
          'b': [3, [2, [1, 0]], 1]
        }, {
          'a': [0, 1, 2, [3, [1, 0]], 4, 5],
          'b': [6, [1, [0, 1]], 3, 2, 4, 7]
        }, {
          'a': [0, 1, 2, 3, 4, 5],
          'b': [6, [1, [1]], 7, [3, [1]], [2, [1]], [4, [1]]]
        }, {
          'a': [0, 1, [2, [0]], 3, [4, [0]], 5],
          'b': [6, 7, 3, 2, 4]
        }, {
          'a': [0, [2, [0]], [3, [0]], [4, [0]], 5],
          'b': [6, 1, 7, 3, 2, 4]
        }];
      for (var t in tests) {
        final a0 = t['a'];
        final b0 = t['b'];
        final name = t['name'] == null ? '$a0 => $b0' : t['name'];

        final testFn = t['solo'] == true ? solo_test : test;

        testFn(name, () {
          final a = e(0, gen(a0));
          final b = e(0, gen(b0));
          checkSync(a, b);
        });
      }
    });
  });
}
