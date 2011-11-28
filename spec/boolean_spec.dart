class BooleanSpec extends Spec {
  spec() {

    it("defaults boolean argument values to false (instead of null)", (){
      expect(options.foo) == null;

      options.boolean('foo');

      expect(options.foo) == false;
    });

    it("if a boolean option is passed, it's marked as true", (){
      options.boolean('foo');

      options.arguments = ["someArg", "--foo", "anotherArg"];

      expect(options.foo) == true;
      expect(options._).equalsSet(["someArg", "anotherArg"]);
    });

    it("is chainable", (){
      options.boolean('foo').boolean('bar');
      expect(options.foo) == false;
      expect(options.bar) == false;

      options.arguments = ["hello", "--foo", "world", "--bar"];

      expect(options.foo) == true;
      expect(options.bar) == true;
      expect(options._).equalsSet(["hello", "world"]);
    });

    it("works correctly with aliases", (){
      [options.f, options.foo, options.b, options.bar].forEach((val) => expect(val) == null);

      // Note: currently, you MUST define an alias BEFORE trying to use that alias 
      //       in other configuration commands, eg. boolean.
      options.alias('f', 'foo').alias('b', 'bar')
             .boolean('foo').boolean('b');
      
      [options.f, options.foo, options.b, options.bar].forEach((val) => expect(val) == false);

      options.arguments = ["hello", "--foo", "world"];
      [options.f, options.foo].forEach((val) => expect(val) == true);
      [options.b, options.bar].forEach((val) => expect(val) == false);
      expect(options._).equalsSet(["hello", "world"]);

      options.arguments = ["hello", "--foo", "world", "-b"];
      [options.f, options.foo, options.b, options.bar].forEach((val) => expect(val) == true);
      expect(options._).equalsSet(["hello", "world"]);
    });

    it("can pass false values (--no-foo)", (){
      options.boolean("foo");
      expect(options.foo) == false;

      options.defaults("foo", true);
      expect(options.foo) == true;

      options.arguments = ["--no-foo"];
      expect(options.foo) == false;

      options.arguments = ["--foo"];
      expect(options.foo) == true;
    });

    it("can pass false values with aliases (-no-f)", (){
      options.boolean("foo").alias("f", "foo");
      expect(options.f) == false;

      options.defaults("f", true);
      expect(options.f)   == true;
      expect(options.foo) == true;

      options.arguments = ["--no-f"];
      expect(options.f)   == false;
      expect(options.foo) == false;

      options.arguments = ["--foo"];
      expect(options.f)   == true;
      expect(options.foo) == true;
    });
  }
}
