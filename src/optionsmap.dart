#library("optionsmap");

// Note: this should have as few arguments as possible on it, to avoid collisions with argument names.
// Note: you should be able to get the raw Map that we create, so you can deal with collisions if/when they happen.
// Note: you should also be able to getArgument (first value or null) or getArguments (array of all values).
class OptionsMap {
  static final RegExp argumentNamePattern    = const RegExp(@"^-{1,2}([^=]*)(=.*)?");
  static final RegExp parseIntPattern        = const RegExp(@"^\d+$");
  static final RegExp parseDoublePattern     = const RegExp(@"^\d+\.\d+$");
  static final String defaultArgumentName    = "_";

  List<String> arguments;

  bool parseValues = true;

  Map<String,String>  _aliases;
  Map<String,List>    _defaults;
  List<String>        _booleans;

  OptionsMap([List<String> arguments = null]) {
    this.arguments = (arguments == null) ? new Options().arguments : arguments;
    _aliases  = new HashMap<String,String>();
    _defaults = new HashMap<String,List>();
    _booleans = new List<String>();
  }

  OptionsMap alias(String key1, String key2) {
    _aliases[key1] = key2;
    return this;
  }

  OptionsMap boolean(String key) {
    _booleans.add(_key(key));
    return this;
  }

  bool isBoolean(String key) => _booleans.indexOf(_key(key)) > -1;

  OptionsMap defaults(String key, Dynamic defaultValue) {
    _defaults[_key(key)] = (defaultValue is List) ? defaultValue : [defaultValue];
    return this;
  }

  // Builds a new map each time, based on the current arguments (and config).
  // We'll memoize this (and expire on config/arg changes) in the future.
  // We may or may not keep this public ... recommend making it private, atleast for now?
  // TODO FIXME refactor me (after implementing a few more features) because I'm sad
  Map<String,List> get map() {
    var theMap      = new HashMap<String,List>();
    var currentName = null;
    var setValue    = (key, value) {
      key = _key(key);
      theMap.putIfAbsent(key, ()=>[]);
      theMap[key].add(_parse(value));
    };

    for (String arg in arguments) {

      if (arg.startsWith("--no-") && arg.length > 5) {
        String name = arg.substring(5);
        if (isBoolean(name)) {
          setValue(name, false);
          currentName = null;
          continue;
        }
      }

      if (currentName == null) {
        var match = argumentNamePattern.firstMatch(arg);
        if (match == null) { // This isn't a named argument.  Add it to the unnamed args.
          setValue(defaultArgumentName, arg);
        } else if (match[2] != null && match[2].length > 0) { // This is a name and value, eg. --foo=bar
          setValue(match[1], match[2].substring(1));
        } else {
          currentName = match[1];
          if (isBoolean(currentName)) {
            setValue(currentName, true);
            currentName = null;
          }
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

  // TODO are we using "name" or "key" or what?  Make up your mind!  And FIXME  :)
  Dynamic getArguments([String name = null]) {
    name = _key(name);
    if (name == null) name = defaultArgumentName;
    if (map.containsKey(name))
      return map[name];
    else
      return _getDefault(name);
  }

  void noSuchMethod(String methodName, List arguments) {
    if (methodName.startsWith("get:")) {
      var name = methodName.substring(4);
      if (name.startsWith("_@")) name = defaultArgumentName; // hack for ._
      name = _findNameFromMethod(name);
      var arguments = getArguments(name);
      switch (arguments.length) {
        case 0:  return isBoolean(name) ? false : null;
        case 1:  return arguments[0];
        default: return arguments;
      }
    }

    super.noSuchMethod(methodName, arguments);
  }

  // Handles mapping key names to their aliases to get the 
  // "real" key that we store in our map for these arguments.
  String _key(String key) {
    if (key === null) return key;
    return (_aliases.containsKey(key)) ? _key(_aliases[key]) : key;
  }

  Dynamic _getDefault(String key) {
    key = _key(key);
    return _defaults.containsKey(key) ? _defaults[key] : [];
  }

  Dynamic _parse(argument) {
    if (parseValues == false)   return argument;
    if (! (argument is String)) return argument; // for now, we only parse strings

    if (parseDoublePattern.hasMatch(argument))
      return Math.parseDouble(argument);
    else if (parseIntPattern.hasMatch(argument))
      return Math.parseInt(argument);
    else
      return argument;
  }

  String _findNameFromMethod(String originalName) {
    if (map.isEmpty() || map.containsKey(originalName))
      return originalName;

    String withoutPunctuation = _withoutPunctuation(originalName);
    for (String key in map.getKeys())
      if (_withoutPunctuation(key) == withoutPunctuation)
        return key;

    return originalName;
  }

  // String.replace[All] isn't implemented with Regexp yet  :/
  _withoutPunctuation(String str) => str.replaceAll("-", "").replaceAll("_", "");
}
