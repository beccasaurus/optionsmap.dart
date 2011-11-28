class DefaultSpec extends Spec {
  OptionsMap options;

  spec() {
    
    before((){ options = new OptionsMap([]); });

    before((){
      expect(options.foo) == null;
      expect(options.getArgument("foo")) == null;
      expect(options.getArguments("foo")).equalsSet([]);
    });

    it("defaults('foo', 'some value')", (){
      options.defaults("foo", "some value");
      expect(options.foo) == "some value";

      options.arguments = ["--foo", "override!"];
      expect(options.foo) == "override!";
    });

    it("defaults('foo', 5)", (){
      options.defaults("foo", 5);
      expect(options.foo) == 5;

      options.arguments = ["--foo", "override!"];
      expect(options.foo) == "override!";
    });

    it("defaults('foo', true)", (){
      options.defaults("foo", true);
      expect(options.foo) == true;

      options.arguments = ["--foo", "override!"];
      expect(options.foo) == "override!";
    });

    it("works correctly with aliases", (){
      expect(options.f) == null;

      options.alias('f', 'foo').defaults('f', 5);
      
      expect(options.f)   == 5;
      expect(options.foo) == 5;

      options.arguments = ["-f", "override!"];

      expect(options.f)   == "override!";
      expect(options.foo) == "override!";
    });

    it("works correctly with getArgument", (){
      options.defaults("foo", "some value");
      expect(options.getArgument("foo")) == "some value";

      options.arguments = ["--foo", "override!"];
      expect(options.getArgument("foo")) == "override!";
    });

    it("works correctly with getArguments", (){
      options.defaults("foo", "some value");
      expect(options.getArguments("foo")).equalsSet(["some value"]);

      options.arguments = ["--foo", "override!"];
      expect(options.getArguments("foo")).equalsSet(["override!"]);

      options.arguments = ["--foo", "override!", "--foo", "more"];
      expect(options.getArguments("foo")).equalsSet(["override!", "more"]);
    });

    describe("using a List as the default value", (){

      before((){
        options.defaults("foo", [1, "two"]);
      });

      it("defaults('foo', ['one', 'two'])", (){
        expect(options.foo).equalsSet([1, "two"]);

        options.arguments = ["--foo", "override!"];
        expect(options.foo) == "override!";
      });

      it("works correctly with aliases", (){
        expect(options.f) == null;

        options.alias('f', 'foo');
        
        expect(options.f).equalsSet([1, "two"]);
        expect(options.foo).equalsSet([1, "two"]);
        
        options.arguments = ["--foo", "override!"];
        expect(options.f)   == "override!";
        expect(options.foo) == "override!";
      });

      it("works correctly with getArgument", (){
        expect(options.getArgument("foo")) == 1;

        options.arguments = ["--foo", "override!"];
        expect(options.getArgument("foo")) == "override!";
      });

      it("works correctly with getArguments", (){
        expect(options.getArguments("foo")).equalsSet([1, "two"]);

        options.arguments = ["--foo", "override!"];
        expect(options.getArguments("foo")).equalsSet(["override!"]);

        options.arguments = ["--foo", "override!", "--foo", "more"];
        expect(options.getArguments("foo")).equalsSet(["override!", "more"]);
      });
    });
  }
}
