class BooleanSpec extends Spec {
  OptionsMap options; // TODO after this spec, let's refactor this into our Spec baseclass cuz, jeez, we use it everywhere!  (same as the before block)

  spec() {
    
    before((){ options = new OptionsMap([]); });

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

    it("can pass false values (which is useful is the default is set to true)", (){
      pending("need to implement default() before we can test this, so we can set the default to true");
    });
  }
}
