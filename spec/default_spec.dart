class DefaultSpec extends Spec {
  OptionsMap options;

  spec() {
    
    before((){ options = new OptionsMap([]); });

    it("default('foo', 'some value')");

    it("default('foo', 5)");

    it("default('foo', true)");

    it("default('foo', ['one', 'two'])");
  }
}
