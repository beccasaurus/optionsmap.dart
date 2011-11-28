#library("optionsmap");

class OptionsMap {
  static final RegExp argumentNamePattern    = const RegExp(@"^-{1,2}([^=]*)(=.*)?");
  static final RegExp parseIntPattern        = const RegExp(@"^\d+$");
  static final RegExp parseDoublePattern     = const RegExp(@"^\d+\.\d+$");
  static final String defaultArgumentName    = "_";

  /** Returns the raw arguments used to instantiate this 
      OptionMap (or the default command line arguments). */
  List<String> arguments;

  /** If set to false, [:String:] arguments that look like 
      numbers are not parsed into numbers. */
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

  /** Aliases a [:newName:] to an [:existingName:] eg. [:alias("f", "foo"):].
    *
    * Not only does this allow you to call your program with [:-f val:] as 
    * a shortcut for [:--foo val:], but you will also be able to access the 
    * value as [:options.f:] instead of [:options.foo:].
    *
    * NOTE: if you want to call [boolean], [defaults], etc using an alias's 
    *       argument name, you should do this *after* calling [alias].
    */
  OptionsMap alias(String newName, String existingName) {
    _aliases[newName] = existingName;
    return this;
  }

  /** Marks the given argument as a boolean, meaning that it accepts no value. 
    * By default, all boolean arguments are [:false:] (as opposed to [:null:]. 
    * To set a boolean value to [:true:], simply call your program with the argument 
    * eg. [:--foo:].  You can also call [:--no-foo:] to explicitly set the argument 
    * value to [:false:] (useful if it [defaults] to [:true:]). */
  OptionsMap boolean(String key) {
    _booleans.add(_key(key));
    return this;
  }

  /** Returns whether or not the given argument name is for a boolean argument. */
  bool isBoolean(String key) => _booleans.indexOf(_key(key)) > -1;

  /** Sets a default value for the given argument name.  May be a single value or 
    * a [:List:] of values (as arguments may have multiple values). */
  OptionsMap defaults(String key, Dynamic defaultValue) {
    _defaults[_key(key)] = (defaultValue is List) ? defaultValue : [defaultValue];
    return this;
  }

  Dynamic getArgument([String name = null]) {
    List arguments = getArguments(name);
    return (arguments.length > 0) ? arguments[0] : null;
  }

  // TODO are we using "name" or "key" or what?  Make up your mind!  And FIXME  :)
  Dynamic getArguments([String name = null]) {
    name = _key(name);
    if (name == null) name = defaultArgumentName;
    if (_map.containsKey(name))
      return _map[name];
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

  // private

  Map<String,List> get _map() {
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
    if (_map.isEmpty() || _map.containsKey(originalName))
      return originalName;

    String withoutPunctuation = _withoutPunctuation(originalName);
    for (String key in _map.getKeys())
      if (_withoutPunctuation(key) == withoutPunctuation)
        return key;

    return originalName;
  }

  // String.replace[All] isn't implemented with Regexp yet  :/
  _withoutPunctuation(String str) => str.replaceAll("-", "").replaceAll("_", "");
}
