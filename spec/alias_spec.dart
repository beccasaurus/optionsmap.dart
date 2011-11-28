class AliasSpec extends Spec {
  spec() {

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

    it("is chainable", (){
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
  }
}
