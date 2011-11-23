class OptionsMapSpec extends Spec {
  OptionsMap options;

  spec() {
    
    before((){ options = new OptionsMap([]); });

    it(".arguments defaults to new Options().arguments", (){
      expect(new OptionsMap().arguments).equalsSet(new Options().arguments);
    });

    it(".arguments returns the raw arguments", (){
      options.arguments = ["--foo", "bar"];
      expect(options.getArgument("foo")) == "bar";
      expect(options.arguments).equalsSet(["--foo", "bar"]);
    });

    describe("aliasing", (){
      it("alias('f', 'foo')", (){
        options = new OptionsMap([]).alias("f", "foo");
        [options.f, options.foo].forEach((val) => expect(val) == null);

        options.arguments = ["-f", "hello!"];
        [options.f, options.foo].forEach((val) => expect(val) == "hello!");

        options.arguments = ["--foo", "hello FOO!"];
        [options.f, options.foo].forEach((val) => expect(val) == "hello FOO!");
      });

      it("alias('foo', 'f')", (){
        options = new OptionsMap([]).alias("foo", "f");
        [options.f, options.foo].forEach((val) => expect(val) == null);

        options.arguments = ["-f", "hello!"];
        [options.f, options.foo].forEach((val) => expect(val) == "hello!");

        options.arguments = ["--foo", "hello FOO!"];
        [options.f, options.foo].forEach((val) => expect(val) == "hello FOO!");
      });

      it("alias('foo', 'bar')", (){
        options = new OptionsMap([]).alias("foo", "bar");
        [options.foo, options.bar].forEach((val) => expect(val) == null);

        options.arguments = ["--foo", "hello!"];
        [options.foo, options.bar].forEach((val) => expect(val) == "hello!");

        options.arguments = ["--bar", "hello BAR!"];
        [options.foo, options.bar].forEach((val) => expect(val) == "hello BAR!");
      });

      it("works if you chain aliases together", (){
        // Note: we're mapping f -> foo -> bar
        options = new OptionsMap([]).alias("f", "foo").alias("foo", "bar");
        [options.f, options.foo, options.bar].forEach((val) => expect(val) == null);

        options.arguments = ["-f", "hello!"];
        [options.f, options.foo, options.bar].forEach((val) => expect(val) == "hello!");

        options.arguments = ["--foo", "hello FOO!"];
        [options.f, options.foo, options.bar].forEach((val) => expect(val) == "hello FOO!");

        options.arguments = ["--bar", "hello BAR!"];
        [options.f, options.foo, options.bar].forEach((val) => expect(val) == "hello BAR!");
      });

      it("cannot alias a single name to more than 1 other name", (){
        // Ok, so let's setup f --> foo
        options = new OptionsMap([]).alias("f", "foo");
        expect(options.f)   == null;
        expect(options.foo) == null;
        expect(options.bar) == null;

        options.arguments = ["--foo", "hello!", "--bar", "hello BAR!"];
        expect(options.foo) == "hello!";
        expect(options.bar) == "hello BAR!";
        expect(options.f)   == "hello!"; // This points to foo

        options.alias("f", "bar");
        expect(options.foo) == "hello!";
        expect(options.bar) == "hello BAR!";
        expect(options.f)   == "hello BAR!"; // Now this points to bar
      });
    });

    describe("defaults (no configuration) ", (){
      it("no arguments", (){
        options.arguments = [];
        expect(options.getArguments()).isEmpty();
        expect(options._) == null;
      });

      it("foo bar", (){
        options.arguments = ["foo", "bar"];
        expect(options.getArguments()).equalsSet(["foo", "bar"]);

        expect(options.map.getKeys()).equalsSet(["_"]);
        expect(options.map["_"]).equalsSet(["foo", "bar"]);

        expect(options._).equalsSet(["foo", "bar"]);
      });

      exampleArguments(["--foo=bar", "--foo bar"], (args) {
        options.arguments = args;
        expect(options.getArguments()).isEmpty();
        expect(options.getArguments("foo")).equalsSet(["bar"]);

        expect(options.map.getKeys()).equalsSet(["foo"]);
        expect(options.map["foo"]).equalsSet(["bar"]);
        
        expect(options.foo) == "bar";
        expect(options._) == null;
      });

      exampleArguments(["-f bar", "-f=bar"], (args) {
        options.arguments = args;
        expect(options.getArgument("f")) == "bar";
        expect(options.getArguments("f")).equalsSet(["bar"]);

        expect(options.map.getKeys()).equalsSet(["f"]);
        expect(options.map["f"]).equalsSet(["bar"]);

        expect(options.f) == "bar";
        expect(options._) == null;
      });

      exampleArguments(["hi -f bar there", "-f=bar hi there", "hi there -f bar"], (args) {
        options.arguments = args;
        expect(options.getArgument("_")) == "hi";
        expect(options.getArguments("_")).equalsSet(["hi", "there"]);
        expect(options.getArgument("f")) == "bar";
        expect(options.getArguments("f")).equalsSet(["bar"]);

        expect(options.map.getKeys()).equalsSet(["_", "f"]);
        expect(options.map["_"]).equalsSet(["hi", "there"]);
        expect(options.map["f"]).equalsSet(["bar"]);

        expect(options.f) == "bar";
        expect(options._).equalsSet(["hi", "there"]);
      });

      exampleArguments(["--foo bar --foo anotherValue hello --foo more!"], (args) {
        options.arguments = args;
        expect(options.getArgument("_")) == "hello";
        expect(options.getArguments("_")).equalsSet(["hello"]);
        expect(options.getArgument("foo")) == "bar";
        expect(options.getArguments("foo")).equalsSet(["bar", "anotherValue", "more!"]);

        expect(options.map.getKeys()).equalsSet(["_", "foo"]);
        expect(options.map["_"]).equalsSet(["hello"]);
        expect(options.map["foo"]).equalsSet(["bar", "anotherValue", "more!"]);

        expect(options._) == "hello";
        expect(options.foo).equalsSet(["bar", "anotherValue", "more!"]);
      });
    });

  }
}
