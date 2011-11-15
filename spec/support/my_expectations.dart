class MyExpectations extends CoreExpectations implements Expectationable {
  MyExpectations(var target) : super(target);

  MyExpectations get not() {
    positive = false;
    return this;
  }

  isEmpty() {
    var length = 0;
    if (target is Map) {
      length = target.getKeys().length;
    } else if (target is Collection) {
      length = target.length;
    } else if (target is Iterable) {
      for (var item in target) ++length;
    } else {
      throw new IllegalArgumentException("isEmpty expects an Iterable, got: $target");
    }

    if (positive) 
      expect(length).equals(0, reason: "Expected isEmpty: $targetText");
    else
      expect(length).notEquals(0, reason: "Expected not.isEmpty: ${target.toString()}");
  }

  String get targetText() => objectToString(target);
}
