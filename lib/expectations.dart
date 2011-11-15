/* src/expectations.dart */
#library("expectations");

/* src/expectations/expectationable.dart */
/**
 * [:expect():] returns an [Expectationable] object that has the functions 
 * you want to call on it, eg. isNull for expect(foo).isNull
 *
 * An [Expectationable] class has a constructor that takes any type 
 * of object and provides functions that make Expect assertions on 
 * that object, eg. [:new MyExpectationable("Foo").toEqual("Bar"):]
 *
 * An [Expectationable] instance is meant to be returned by 
 * [:expect():], eg. [:expect("Foo").toEqual("Bar"):].
 */
interface Expectationable {
  var target;
  Expectationable(var target);
}
/* src/expectations/expectationable_selector.dart */
/**
* An ExpectationableSelector is a function that, given 
* a target object, can return either:
*
*  - an instance of an Expectationable class, initialized with the 
*    target object, so we can call the functions that the Expectationable 
*    class provides on the target object, eg. toEqual()
*
*  - or null to indicate that we don't want to run expectations on 
*    the given target, so another ExpectationableSelector 
*    should be checked to return an Expectationable.
*/
typedef Expectationable ExpectationableSelector(var target);
/* src/expectations/no_expectationable_found_exception.dart */
/**
 * Exception that is thrown when expect() is called but none of 
 * the expectationableSelectors (registered via Expectations.onExpect()) 
 * returned an instance of Expectationable that could be returned from expect()
 */
class NoExpectationableFoundException implements Exception {
  var  target;
  bool noSelectors;

  NoExpectationableFoundException(var target, [bool noSelectors = false]) {
    this.target      = target;
    this.noSelectors = noSelectors;
  }

  String toString() {
    if (noSelectors == true)
      return "No Expectations.expectationableSelectors() were found.  Try calling Expectations.onExpect(fn).";
    else
      return "No Expectations.expectationableSelectors() returned an Expectationable for target: $target";
  }
}
/* src/expectations/core_expectations.dart */
/**
 * By default, [Expectations] uses [CoreExpectations] for all of its expectations. 
 * In other words, calling [:expect("foo"):] returns an instance of [CoreExpectations].
 *
 * This class provides 1 method for every method available on [:Expect:].  The names map 
 * very closely to the originals, eg. [:Expect.equals(a, b):] becomes [:expect(b).equals(a):].
 *
 * There are a few notable differences, eg. [:Expect.listEquals(a, b):] becomes [:expect(b).equalsCollection(a):]. 
 * These method names were inspired the Dart unit test library, unittest: 
 * http://code.google.com/p/dart/source/browse/trunk/dart/client/testing/unittest/unittest.dart?r=1052 
 *
 */
class CoreExpectations implements Expectationable {
  var target;
  bool positive;

  CoreExpectations(target) {
    this.target   = target;
    this.positive = true;
  }

  CoreExpectations get not() {
    var core = new CoreExpectations(target);
    core.positive = false;
    return core;
  }

  /** See Expect.approxEquals. */
  void approxEquals(num expected, [num tolerance = 0.000100, String reason = null]) {
    _runExpectation(
      (){ Expect.approxEquals(expected, target, tolerance: tolerance, reason: reason); },
      () => "Expect.not.approxEquals(unexpected:<$expected>, actual:<$target>, tolerance:<$tolerance>${_reasonText(reason)}) fails");
  }

  /** See Expect.equals. */
  void equals(var expected, [String reason = null]) {
    if (positive)
      Expect.equals(expected, target, reason: reason);
    else
      if (expected == target)
        throw new ExpectException("Expect.not.equals(unexpected: <$expected>, actual: <$target>${_reasonText(reason)}) fails.");
  }

  /** See [equals]. */
  operator ==(var object) {
    equals(object);
  }

  /** See Expect.fail(). */
  void fail([String reason = "no reason given"]) {
    if (positive != true) throw new UnsupportedOperationException("fail cannot be called with .not");
    Expect.fail(reason);
  }

  // See Expect.identical()
  void identical(expected, [String reason = null]) {
    if (positive)
      Expect.identical(expected, target, reason: reason);
    else
      if (expected === target)
        throw new ExpectException("Expect.not.identical(unexpected: <$expected>, actual: <$target>${_reasonText(reason)}) fails.");
  }

  /** See Expect.isFalse(). */
  void isFalse([String reason = null]) {
    if (positive != true) throw new UnsupportedOperationException("isFalse cannot be called with .not");
    Expect.isFalse(target, reason: reason);
  }

  /** See Expect.isNotNull(). */
  void isNotNull([String reason = null]) {
    if (positive != true) throw new UnsupportedOperationException("isNotNull cannot be called with .not");
    Expect.isNotNull(target, reason: reason);
  }

  /** See Expect.isNull().  */
  void isNull([String reason = null]) {
    if (positive == true)
      Expect.isNull(target, reason: reason);
    else
      if (null === target)
        throw new ExpectException("Expect.not.isNull($target${_reasonText(reason)}) fails.");
  }

  /** See Expect.isTrue(). */
  void isTrue([String reason = null]) {
    if (positive == true)
      Expect.isTrue(target, reason: reason);
    else
      if (true === target)
        throw new ExpectException("Expect.not.isTrue($target${_reasonText(reason)}) fails.");
  }

  /** See Expect.listEquals(). */
  void equalsCollection(Collection expected, [String reason = null]) {
    _runExpectation(
      (){ Expect.listEquals(expected, target, reason: reason); },
      () => "Expect.not.listEquals(${_iterableText(target)}${_reasonText(reason)}) fails");
  }

  /** See Expect.notEquals(). */
  void notEquals(value, [String reason = null]) {
    if (positive != true) throw new UnsupportedOperationException("notEquals cannot be called with .not");
    Expect.notEquals(value, target, reason: reason);
  }

  /** See Expect.setEqual(). */
  void equalsSet(Iterable expected, [String reason = null]) {
    _runExpectation(
      (){ Expect.setEquals(expected, target, reason: reason); },
      () => "Expect.not.setEquals(${_iterableText(target)}${_reasonText(reason)}) fails");
  }

  /** See Expect.stringEquals(). */
  void equalsString(String value, [String reason = null]) {
    _runExpectation(
      (){ Expect.stringEquals(value, target, reason: reason); },
      () => "Expect.not.stringEquals('$target'${_reasonText(reason)}) fails");
  }

  /** See Expect.throws(). */
  void throws([check = null, String reason = null]) {
    if (positive) {
      Expect.throws(target, check: check, reason: reason);
    } else {
      // I'm not sure what the "expected" behavior of check: would be when 
      // called as expect().not.throws(check: ...) so it's currently unsupported.
      if (check != null)
        throw new UnsupportedOperationException("the :check parameter of throws() is unsupported when called with .not");
      try {
        target();
      } catch (Exception ex) {
        throw new ExpectException("Expect.not.throws(unexpected: <$ex>${_reasonText(reason)}) fails");
      }
    }
  }

  // This does some evil to make the .not statements work by calling 
  // the *positive* version of the expectation and passing if an 
  // ExpectException was thrown by the positive expectation.
  //
  // NOTE: This implementation isn't ideal!  Exceptions shouldn't be 
  //       thrown within *passing* expectations.
  void _runExpectation(void passingCode(), String notFailureMessage()) {
    if (positive == true) {
      // This code should pass, so we just run it!
      // If it blows up, that means a legit failure
      passingCode();
    } else {
      // If .not was used, we *expect* the passingCode to actually fail.
      // If we get an ExpectException that looks right, then this was successful.
      // Otherwise, we throw the Exception that we got, directly.
      ExpectException expectedException;
      try {
        passingCode();
      } catch (ExpectException ex) {
        expectedException = ex;
      }
      
      // We expected to get an exception.
      // The code must have passed, meaning the "not" failed!"
      if (expectedException == null)
        throw new ExpectException(notFailureMessage());
    }
  }

  String _reasonText(String reason) {
    return (reason == null) ? "" : ", '$reason'";
  }

  String _iterableText(Iterable collection) {
    List<String> stringRepresentations = new List<String>();
    for (var item in collection)
      stringRepresentations.add(item.toString());
    return "[" + Strings.join(stringRepresentations, ", ") + "]";
  }
}
/* src/expectations/to_be_expectations.dart */
/**
 * [ToBeExpectations] is an alternative set of expectations providing 
 * a syntax like: [:expect("foo").toEqual("bar"):]
 *
 * This was inspired by the [:expect():] syntax of the popular JavaScript 
 * test framework, Jasmine: http://pivotal.github.com/jasmine/
 */
class ToBeExpectations implements Expectationable {
  var target;
  bool positive;

  ToBeExpectations(target) {
    this.target   = target;
    this.positive = true;
  }

  ToBeExpectations get not() {
    var core = new ToBeExpectations(target);
    core.positive = false;
    return core;
  }

  /** See Expect.approxEquals. */
  void toApproxEqual(num expected, [num tolerance = 0.000100, String reason = null]) {
    _runExpectation(
      (){ Expect.approxEquals(expected, target, tolerance: tolerance, reason: reason); },
      () => "Expect.not.approxEquals(unexpected:<$expected>, actual:<$target>, tolerance:<$tolerance>${_reasonText(reason)}) fails");
  }

  /** See Expect.equals. */
  void toEqual(var expected, [String reason = null]) {
    if (positive)
      Expect.equals(expected, target, reason: reason);
    else
      if (expected == target)
        throw new ExpectException("Expect.not.equals(unexpected: <$expected>, actual: <$target>${_reasonText(reason)}) fails.");
  }

  // /** See [equals]. */
  operator ==(var object) {
    toEqual(object);
  }

  /** See Expect.fail(). */
  void fail([String reason = "no reason given"]) {
    if (positive != true) throw new UnsupportedOperationException("fail cannot be called with .not");
    Expect.fail(reason);
  }

  // See Expect.identical()
  void toBe(expected, [String reason = null]) {
    if (positive)
      Expect.identical(expected, target, reason: reason);
    else
      if (expected === target)
        throw new ExpectException("Expect.not.identical(unexpected: <$expected>, actual: <$target>${_reasonText(reason)}) fails.");
  }

  /** See Expect.isFalse(). */
  void toBeFalse([String reason = null]) {
    if (positive != true) throw new UnsupportedOperationException("toBeFalse cannot be called with .not");
    Expect.isFalse(target, reason: reason);
  }

  /** See Expect.isNotNull(). */
  void toNotBeNull([String reason = null]) {
    if (positive != true) throw new UnsupportedOperationException("toNotBeNull cannot be called with .not");
    Expect.isNotNull(target, reason: reason);
  }

  /** See Expect.isNull().  */
  void toBeNull([String reason = null]) {
    if (positive == true)
      Expect.isNull(target, reason: reason);
    else
      if (null === target)
        throw new ExpectException("Expect.not.isNull($target${_reasonText(reason)}) fails.");
  }

  /** See Expect.isTrue(). */
  void toBeTrue([String reason = null]) {
    if (positive == true)
      Expect.isTrue(target, reason: reason);
    else
      if (true === target)
        throw new ExpectException("Expect.not.isTrue($target${_reasonText(reason)}) fails.");
  }

  /** See Expect.listEquals(). */
  void toEqualList(List expected, [String reason = null]) {
    _runExpectation(
      (){ Expect.listEquals(expected, target, reason: reason); },
      () => "Expect.not.listEquals(${_iterableText(target)}${_reasonText(reason)}) fails");
  }

  /** See Expect.notEquals(). */
  void toNotEqual(value, [String reason = null]) {
    if (positive != true) throw new UnsupportedOperationException("toNotEqual cannot be called with .not");
    Expect.notEquals(value, target, reason: reason);
  }

  /** See Expect.setEqual(). */
  void toEqualSet(Iterable expected, [String reason = null]) {
    _runExpectation(
      (){ Expect.setEquals(expected, target, reason: reason); },
      () => "Expect.not.setEquals(${_iterableText(target)}${_reasonText(reason)}) fails");
  }

  /** See Expect.stringEquals(). */
  void toEqualString(String value, [String reason = null]) {
    _runExpectation(
      (){ Expect.stringEquals(value, target, reason: reason); },
      () => "Expect.not.stringEquals('$target'${_reasonText(reason)}) fails");
  }

  /** See Expect.throws(). */
  void toThrow([check = null, String reason = null]) {
    if (positive) {
      Expect.throws(target, check: check, reason: reason);
    } else {
      // I'm not sure what the "expected" behavior of check: would be when 
      // called as expect().not.throws(check: ...) so it's currently unsupported.
      if (check != null)
        throw new UnsupportedOperationException("the :check parameter of toThrow() is unsupported when called with .not");
      try {
        target();
      } catch (Exception ex) {
        throw new ExpectException("Expect.not.throws(unexpected: <$ex>${_reasonText(reason)}) fails");
      }
    }
  }

  // This does some evil to make the .not statements work by calling 
  // the *positive* version of the expectation and passing if an 
  // ExpectException was thrown by the positive expectation.
  //
  // NOTE: This implementation isn't ideal!  Exceptions shouldn't be 
  //       thrown within *passing* expectations.
  void _runExpectation(void passingCode(), String notFailureMessage()) {
    if (positive == true) {
      // This code should pass, so we just run it!
      // If it blows up, that means a legit failure
      passingCode();
    } else {
      // If .not was used, we *expect* the passingCode to actually fail.
      // If we get an ExpectException that looks right, then this was successful.
      // Otherwise, we throw the Exception that we got, directly.
      ExpectException expectedException;
      try {
        passingCode();
      } catch (ExpectException ex) {
        expectedException = ex;
      }
      
      // We expected to get an exception.
      // The code must have passed, meaning the "not" failed!"
      if (expectedException == null)
        throw new ExpectException(notFailureMessage());
    }
  }

  String _reasonText(String reason) {
    return (reason == null) ? "" : ", '$reason'";
  }

  String _iterableText(Iterable collection) {
    List<String> stringRepresentations = new List<String>();
    for (var item in collection)
      stringRepresentations.add(item.toString());
    return "[" + Strings.join(stringRepresentations, ", ") + "]";
  }
}

/**
 * The expect() function is defined globally so you can easily call 
 * it from within your own test suites (or wherever).
 *
 * Example usage: expect("Foo").toEqual("Bar");
 *
 * If you want to implement your own expectations so 
 * you can call expect("Foo").toSomethingCustom(), 
 * see Expectations.onExpect()
 */
Expectationable expect([var target = null]) => Expectations.expect(target);

/**
 * [Expectations] houses the logic for the top-level [:expect():] 
 * method, including determining what [Expectationable] instance to 
 * return (which is where expectation methods are defined).
 * 
 * See [:Expectations.expect():] for main [:expect():] implementation.
 * See [:Expectations.onExpect():] to use your own custom [Expectationable].
 */
class Expectations {

  /** Returns the vurrent version of Expectations */
  static final VERSION = "0.1.0";

  static List<ExpectationableSelector> _expectationableSelectors;
  static ExpectationableSelector       _defaultExpectationableSelector;

  /**
   * Default [:ExpectationableSelector:] that we include in 
   * expectationableSelectors which always returns an instance of [Expectations]. */
  static ExpectationableSelector get defaultExpectationableSelector() {
    if (_defaultExpectationableSelector === null)
      _defaultExpectationableSelector = (target) => new CoreExpectations(target);
    return _defaultExpectationableSelector;
  }

  /**
   * A list of functions that are iterated through and each called 
   * to determine what [Expectationable] instance to return from expect().
   *
   * When each function is called, it can look at the target object 
   * to determine whether to return null or an instance of Expectationable 
   * that has been instantiated with the target object, allowing us to 
   * return that from [:expect():].
   */
  static List<ExpectationableSelector> get expectationableSelectors() {
    if (_expectationableSelectors === null) {
      _expectationableSelectors = new List<ExpectationableSelector>();
      _expectationableSelectors.add(defaultExpectationableSelector);
    }
    return _expectationableSelectors;
  }

  /**
   * [:onExpect:] takes a [:ExpectationableSelector:] and configures 
   * it to be called whenever [:expect():] is called, allowing this function 
   * to return a custom [Expectationable] object for the target provided.
   *
   * The [:ExpectationableSelector:] provided will be added to the front 
   * of [:expectationableSelectors():].  If your function returns null, we will 
   * continue iterations over the rest of the [:expectationableSelectors():] that 
   * were registered via [:onExpect():] until we finally find an [Expectationable] class 
   * to return from [:expect():] (or an Exception will be thrown if none are found).
   */
  static void onExpect(ExpectationableSelector fn) {
    expectationableSelectors.insertRange(0, 1, fn);
  }

  // When given an ExpectationableSelector, this clears out all other 
  // selector callback functions (eg. those registered via onExpect) and 
  // sets this to be the only function, so only this function will handle 
  // what Expectationable object to return from expect().
  static void setExpectationableSelector(ExpectationableSelector fn) {
    expectationableSelectors.clear();
    expectationableSelectors.add(fn);
  }

  // Resets expectationableSelectors back to its default (which always returns an 
  // instance of Expectations from expect())
  static void setDefaultExpectationableSelector() {
    Expectations.setExpectationableSelector(Expectations.defaultExpectationableSelector);
  }

  // Wraps the target object in an instance of an Expectationable that 
  // should provide useful Expect-style functions, eg. toEqual() so 
  // you can write expect(someNumber).toEqual(5).
  static Expectationable expect(var target) {
    if (expectationableSelectors.length == 0)
      throw new NoExpectationableFoundException(target, noSelectors: true);

    Expectationable expectationable;
    for (ExpectationableSelector selector in expectationableSelectors) {
      expectationable = selector(target);
      if (expectationable !== null)
        break;
    }
    if (expectationable === null)
      throw new NoExpectationableFoundException(target);
    return expectationable;
  }
}
