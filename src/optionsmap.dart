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
  OptionsMap boolean(String argumentName) {
    _booleans.add(_key(argumentName));
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

  /** Returns the value of the given argument name (or null).
    *
    * Note: If the given argument has multiple values, only the first value will be returned. */
  Dynamic getArgument([String name = null]) {
    List arguments = getArguments(name);
    return (arguments.length > 0) ? arguments[0] : null;
  }

  /** Returns a [:List:] of all of the value for the given argument name. 
    *
    * If the arguments are [:--foo 5:] then [:getArguments("foo"):] would return [:[5]:] 
    * but, if multiple [:--foo:] values are passed, they will all be returned in this list. */
  Dynamic getArguments([String argumentName = null]) {
    argumentName = _key(argumentName);
    if (argumentName == null) argumentName = defaultArgumentName;
    if (_map.containsKey(argumentName))
      return _map[argumentName];
    else
      return _getDefault(argumentName);
  }

  /** Allows you to call [:options.foo:] and get the value of the [:foo:] argument (or null). 
    *
    * This is very similar to calling [getArgument] or [getArguments] except:
    *
    *  - if only 1 value has been provided for the argument, this returns that value
    *  - if more than 1 vale has been provided, this returns a [:List:] of the provided values
    *  - if no value has been set for this argument, this returns [:null:]
    */
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

  // TODO clean me up, I'm sad.
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

  /** Returns the real, private key that we use to store the given argument in our Map. */
  String _key(String argumentName) {
    if (argumentName === null) return key;
    return (_aliases.containsKey(argumentName)) ? _key(_aliases[argumentName]) : argumentName;
  }

  /** Returnst he default value for this argument (as a [:List:] to be returned from [getArguments]). */
  Dynamic _getDefault(String argumentName) {
    argumentName = _key(argumentName);
    return _defaults.containsKey(argumentName) ? _defaults[argumentName] : [];
  }

  /** Given a raw argument value (String or null), this looks to see if the given argument 
    * looks like a number and, if so, parses it as a number and returns the number. */
  Dynamic _parse(Dynamic argumentValue) {
    if (parseValues == false)   return argumentValue;
    if (! (argumentValue is String)) return argumentValue; // for now, we only parse strings

    if (parseDoublePattern.hasMatch(argumentValue))
      return Math.parseDouble(argumentValue);
    else if (parseIntPattern.hasMatch(argumentValue))
      return Math.parseInt(argumentValue);
    else
      return argumentValue;
  }

  /** Given the name of a method that triggered our [noSuchMethod] implementation, 
    * this tries to find the value for that argument by trying an exact argument 
    * name match first, then trying it again with all punctuation stripped out.
    * This is necessary to allow [:--foo-bar:] to be accessible as [:options.foo_bar:]. */
  String _findNameFromMethod(String methodName) {
    if (_map.isEmpty() || _map.containsKey(methodName))
      return methodName;

    String withoutPunctuation = _withoutPunctuation(methodName);
    for (String key in _map.getKeys())
      if (_withoutPunctuation(key) == withoutPunctuation)
        return key;

    return methodName;
  }

  /** String.replace[All] isn't implemented with Regexp yet so this simply strips out 
    * dashes and underscores from the given string (works for now). */
  _withoutPunctuation(String str) => str.replaceAll("-", "").replaceAll("_", "");
}
