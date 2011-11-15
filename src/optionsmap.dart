#library("optionsmap");

// Note: this should have as few arguments as possible on it, to avoid collisions with argument names.
// Note: you should be able to get the raw Map that we create, so you can deal with collisions if/when they happen.
// Note: you should also be able to getArgument (first value or null) or getArguments (array of all values).
class OptionsMap {
  static final RegExp argumentNamePattern = const RegExp(@"^-{1,2}([^=]*)(=.*)?");
  static final String defaultArgumentName = "_";

  List<String> arguments;

  OptionsMap([List<String> arguments = null]) {
    this.arguments = (arguments == null) ? new Options().arguments : arguments;
  }

  // Builds a new map each time, based on the current argumetns (and config).
  // We'll memoize this (and expire on config/arg changes) in the future.
  Map<String,List> get map() {
    var theMap      = new HashMap<String,List>();
    var currentName = null;
    var setValue    = (key, value) {
      theMap.putIfAbsent(key, ()=>[]);
      theMap[key].add(value);
    };

    for (String arg in arguments) {
      if (currentName == null) {
        var match = argumentNamePattern.firstMatch(arg);
        if (match == null) { // This isn't a named argument.  Add it to the unnamed args.
          setValue(defaultArgumentName, arg);
        } else if (match[2] != null && match[2].length > 0) { // This is a name and value, eg. --foo=bar
          setValue(match[1], match[2].substring(1));
        } else {
          currentName = match[1];
          // when we have booleans, we should add a bool directly to theMap if this is a boolean and unset currentName, so a value doesn't get set.
        }
      } else { // The previous argument was a name, so this is a value.
        setValue(currentName, arg);
        currentName = null;
      }
    }

    return theMap;
  }

  Dynamic getArgument([String name = null]) {
    List arguments = getArguments(name);
    return (arguments.length > 0) ? arguments[0] : null;
  }

  Dynamic getArguments([String name = null]) {
    if (name == null) name = defaultArgumentName;
    if (map.containsKey(name))
      return map[name];
    else
      return [];
  }

  void noSuchMethod(String methodName, List arguments) {
    if (methodName.startsWith("get:")) {
      var name = methodName.substring(4);
      if (name.startsWith("_@")) name = defaultArgumentName; // hack for ._
      var arguments = getArguments(name);
      switch (arguments.length) {
        case 0:  return null;
        case 1:  return arguments[0];
        default: return arguments;
      }
    }

    super.noSuchMethod(methodName, arguments);
  }
}
