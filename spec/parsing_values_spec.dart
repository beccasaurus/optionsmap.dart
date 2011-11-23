class ParsingValuesSpec extends Spec {
  OptionsMap options;

  spec() {
    
    before((){ options = new OptionsMap([]); });

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
  }
}
