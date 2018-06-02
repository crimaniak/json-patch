module vision.json.patch.operation.unittesting;

import std.json : parseJSON;
import vision.json.patch.operation;

unittest
{
	JsonItem a = parseJSON(`{"a":123,"b":"string","c":{"p1":1}}`);
	JsonItem b = parseJSON(`{"b":"string","a":123,"c":{"p1":1}}`);
	JsonItem c = parseJSON(`{"a":123,"b":"string","c":{"p1":2}}`);
	
	assert(a == b);
	assert(a != c);
}

unittest 
{
	import std.stdio;
	
	auto source = parseJSON(`{
		"intProp": 123,
		"stringProp": "just a string",
		"nullProp": null,
		"floatProp": 123.45,
		"arrayProp": [
		    1,
		    "foo",
		    "bar",
		    {
		      "a": 1,
		      "b": "property b"
		    }		   
		],
		"objectProp": {
		    "name": "nested object",
		    "amount": 1,
		    "G": 6.674e-11
		}
	}`);

	
	//writeln(source.toJSON);
	
	// toJsonString()
	assert(new TestOperation("/intProp", JsonItem(123)).toJsonString == `{"op":"test","path":"/intProp","value":123}`, DiffOperation.lastError);
	assert(new TestOperation("/stringProp", JsonItem("just a string")).toJsonString == `{"op":"test","path":"/stringProp","value":"just a string"}`, DiffOperation.lastError);
	assert(new TestOperation("/objectProp/name", JsonItem("nested object")).toJsonString == `{"op":"test","path":"/objectProp/name","value":"nested object"}`, DiffOperation.lastError);
	assert(new AddOperation("/objectProp/c", JsonItem(123)).toJsonString == `{"op":"add","path":"/objectProp/c","value":123}`, DiffOperation.lastError);
	assert(new AddOperation("/arrayProp/-", JsonItem("four")).toJsonString == `{"op":"add","path":"/arrayProp/-","value":"four"}`, DiffOperation.lastError);
	assert(new AddOperation("/a/b", parseJSON(`{"p1":"s1","p2":555}`)).toJsonString == `{"op":"add","path":"/a/b","value":{"p1":"s1","p2":555}}`, DiffOperation.lastError);
	assert(new RemoveOperation("/a/b").toJsonString == `{"op":"remove","path":"/a/b"}`, DiffOperation.lastError);
	assert(new ReplaceOperation("/foo/bar", JsonItem("abc")).toJsonString == `{"op":"replace","path":"/foo/bar","value":"abc"}`, DiffOperation.lastError);
	assert(new MoveOperation("/foo/bar", JsonPointer("/foo/fromhere")).toJsonString == `{"from":"/foo/fromhere","op":"move","path":"/foo/bar"}`, DiffOperation.lastError);
	assert(new CopyOperation("/foo/bar", JsonPointer("/foo/fromhere")).toJsonString == `{"from":"/foo/fromhere","op":"copy","path":"/foo/bar"}`, DiffOperation.lastError);
	
	// test applyTo() 
	assert(new TestOperation("/intProp", JsonItem(123)).applyTo(source), DiffOperation.lastError);
	assert(!new TestOperation("/intProp", JsonItem(1)).applyTo(source), DiffOperation.lastError);
	assert(new TestOperation("/stringProp", JsonItem("just a string")).applyTo(source), DiffOperation.lastError);
	assert(!new TestOperation("/stringProp", JsonItem("wrong string")).applyTo(source), DiffOperation.lastError);
	assert(new TestOperation("/objectProp/name", JsonItem("nested object")).applyTo(source), DiffOperation.lastError);
	
	// add applyTo()
	
	auto empty = parseJSON(`{}`);
	assert(new AddOperation("", source).applyTo(empty), DiffOperation.lastError);
	assert(empty == source);
	
	assert(new AddOperation("/objectProp/c", JsonItem(123)).applyTo(source), DiffOperation.lastError);
	assert(new TestOperation("/objectProp/c", JsonItem(123)).applyTo(source), DiffOperation.lastError);
	
	assert(new AddOperation("/arrayProp/-", JsonItem("four")).applyTo(source), DiffOperation.lastError);
	assert(new TestOperation("/arrayProp/4", JsonItem("four")).applyTo(source), DiffOperation.lastError);

	assert(new AddOperation("/arrayProp/4", JsonItem("four again")).applyTo(source), DiffOperation.lastError);
	assert(new TestOperation("/arrayProp/4", JsonItem("four again")).applyTo(source), DiffOperation.lastError);
	assert(new TestOperation("/arrayProp/5", JsonItem("four")).applyTo(source), DiffOperation.lastError);
	assert(new AddOperation("/arrayProp/6", JsonItem("six")).applyTo(source), DiffOperation.lastError);
	assert(new TestOperation("/arrayProp/6", JsonItem("six")).applyTo(source), DiffOperation.lastError);
	assert(!new AddOperation("/arrayProp/8", JsonItem(0)).applyTo(source), DiffOperation.lastError);

	assert(!new AddOperation("/nonExisting/prop", JsonItem("something")).applyTo(source), DiffOperation.lastError);
	assert(JsonPointer("/nonExisting").evaluate(source).isNull);

	// remove applyTo()
	assert(new RemoveOperation("/arrayProp/4").applyTo(source), DiffOperation.lastError);
	assert(new TestOperation("/arrayProp/4", JsonItem("four")).applyTo(source), DiffOperation.lastError);
	assert(new TestOperation("/arrayProp/5", JsonItem("six")).applyTo(source), DiffOperation.lastError);

	assert(new RemoveOperation("/objectProp/c").applyTo(source), DiffOperation.lastError);
	assert(JsonPointer("/objectProp/c").evaluate(source).isNull);

	assert(!new RemoveOperation("/nonExisting").applyTo(source), DiffOperation.lastError);

	auto simple = parseJSON(`{"intProp": 123}`);
	assert(new RemoveOperation("").applyTo(simple));
	assert(simple == RemoveOperation.emptyObject);
	
	assert(new ReplaceOperation("", source).applyTo(simple));
	assert(simple == source);
	
	simple = parseJSON(`[1,2,3,4,5]`);
	assert(new RemoveOperation("/0").applyTo(simple));
	
	
	assert(!new ReplaceOperation("/nonExisting", JsonItem(0)).applyTo(source));
	
	// copy applyTo()
	assert(new CopyOperation("/objectProp/string", "/stringProp").applyTo(source));
	assert(new TestOperation("/objectProp/string", JsonItem("just a string")).applyTo(source));
	
	assert(new CopyOperation("/arrayProp/2", "/stringProp").applyTo(source));
	assert(new TestOperation("/arrayProp/2", JsonItem("just a string")).applyTo(source));

	assert(!new CopyOperation("/arrayProp/2", "/nonExisting").applyTo(source));
	
	// move applyTo()
	assert(new MoveOperation("/objectProp1", "/objectProp").applyTo(source), DiffOperation.lastError);
	assert(new TestOperation("/objectProp1/name", JsonItem("nested object")).applyTo(source));
	assert(JsonPointer("/objectProp").evaluate(source).isNull);
}

