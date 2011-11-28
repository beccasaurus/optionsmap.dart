class OptionsMapSpec extends Spec {
  OptionsMap options;

  spec() {
    
    // We've been using this in *all* of our specs ... DRY it up?  Just make it CLEAR and not magical ... TODO FIXME
    before((){ options = new OptionsMap([]); });

    it(".arguments defaults to new Options().arguments", (){
      expect(new OptionsMap().arguments).equalsSet(new Options().arguments);
    });

    it(".arguments returns the raw arguments", (){
      options.arguments = ["--foo", "bar"];
      expect(options.getArgument("foo")) == "bar";
      expect(options.arguments).equalsSet(["--foo", "bar"]);
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

      it("converts dashes in key names to underscores (just in noSuchMethod)", (){
        options.arguments = ["--a-b-c", "foo", "--d_e_f", "bar"];

        expect(options.getArgument("a-b-c")) == "foo";
        expect(options.getArgument("d_e_f")) == "bar";

        expect(options.getArgument("a_b_c")) == null;
        expect(options.getArgument("d-e-f")) == null;

        expect(options.a_b_c) == "foo";
        expect(options.d_e_f) == "bar";
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
