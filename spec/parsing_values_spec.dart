class ParsingValuesSpec extends Spec {
  OptionsMap options;

  spec() {
    
    before((){ options = new OptionsMap([]); });

    // TODO - parse arguments into custom/complex objects? --dog rover, eg. could become a <Dog @name="rover">.
    //        if we do this, i want to make a callback (which the int/double parsers should use) that you can hook into.

    describe("by default", (){
      it("--foo bar", (){
        options.arguments = ["--foo", "bar"];
        expect(options.foo) == "bar";
      });

      it("--foo 5", (){
        options.arguments = ["--foo", "5"];
        expect(options.foo) == 5;
      });

      it("--foo 5.123", (){
        options.arguments = ["--foo", "5.123"];
        expect(options.foo) == 5.123;
      });
    });

    describe("with parseValues set to false", (){
      before(() => options.parseValues = false);

      it("--foo bar", (){
        options.arguments = ["--foo", "bar"];
        expect(options.foo) == "bar";
      });

      it("--foo 5", (){
        options.arguments = ["--foo", "5"];
        expect(options.foo) == "5";
      });

      it("--foo 5.123", (){
        options.arguments = ["--foo", "5.123"];
        expect(options.foo) == "5.123";
      });
    });
  }
}
