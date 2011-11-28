#import("../src/optionsmap.dart");
#import("../lib/bullseye.dart");
#import("../lib/expectations.dart");

#source("support/my_expectations.dart");
#source("options_map_spec.dart");
#source("parsing_values_spec.dart");
#source("alias_spec.dart");
#source("boolean_spec.dart");
#source("default_spec.dart");

main() {
  Expectations.onExpect((target) => new MyExpectations(target));
  Bullseye.run([
    new OptionsMapSpec(),
    new ParsingValuesSpec(),
    new AliasSpec(),
    new BooleanSpec(),
    new DefaultSpec()
  ]);
}

class Spec extends BullseyeSpec {
  // Given a list of example arguments (eg. ["-f", "--foo bar"]), this creates 
  // and it() for each example and runs your provided function against each it().
  exampleArguments(List examples, void fn(List<String> arguments)) {
    for (var example in examples) {
      it(objectToString(example), (){
        List<String> args = example.split(" ");
        fn(args);
      });
    }
  }
}

String objectToString(var object) {
  String text = "";
  List toJoin = [];

  if (object is Map) {
    object.forEach((key, value) => toJoin.add("$key: ${objectToString(value)}"));
    text += "{" + Strings.join(toJoin, ", ") + "}";
  } else if (object is Iterable) {
    for (var item in object) toJoin.add(objectToString(item));
    text += "[" + Strings.join(toJoin, ", ") + "]";
  } else {
    text = object.toString();
  }

  return text;
}
