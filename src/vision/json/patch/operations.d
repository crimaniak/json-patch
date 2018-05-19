module vision.json.patch.operations;

import vision.json.patch.commons;
import vision.json.pointer;
import std.range;
import std.typecons: Tuple, tuple;
import std.array;
import std.conv: to;
import std.json;
import std.typecons: scoped;

import std.stdio;

class DiffOperation
{
	alias DataRange = InputRange!(Tuple!(string, const JsonItem));
	
	static string lastError;
	
	const JsonPointer path;
	
	abstract @property string op() pure const @safe;
	
	bool applyTo(ref JsonItem document) const
	{
		return applyToPtr(&document);
	}
	
	bool applyToPtr(JsonItem* document) const
	{
		throw new Exception("Not implemented"); 
	}
	
	this(const string path) @safe
	{
		this.path = JsonPointer(path);
	}
	this(const JsonPointer path) @safe
	{
		this.path = path;
	}
	
	JsonItem toJson() const
	{
		return JsonItem(["op": JsonItem(op), "path": JsonItem(path.toString)]);
	}
	
	string toJsonString() const
	{
		auto json = toJson;
		return json.toJSON(false, JSONOptions.doNotEscapeSlashes);
	}
	
	static bool error(string errorMessage)
	{
		lastError = errorMessage;
		return false;
	}
}

class AddOperation : DiffOperation
{
	JsonItem value;
	override @property string op() pure const @safe { return "add"; }
	
	this(T)(T path, JsonItem value) @safe
	{
		super(path);
		this.value = value;
	}

	override JsonItem toJson() const
	{
		JsonItem retval = super.toJson;
		retval.object["value"] = value;
		return retval;
	}
	
	override bool applyToPtr(JsonItem* document) const
	{
		if(path.isRoot)
		{
			*document = value;
			return true;
		}
		auto parent = path.parent.evaluate(document);
		string index = path.lastComponent;
		
		if(parent.isNull)
			return error("No path "~path.parent.get.toString()~" to add to");
			
		switch(parent.type)
		{
			case JSON_TYPE.ARRAY:
				if(index == "-")
				{
					parent.array ~= value;
				}
				else try 
				{
					import std.array: insertInPlace;
					
					auto numeric = index.to!int;
					if(numeric > parent.array.length)
						return error("Too big index in "~path.toString~", length="~parent.array.length.to!string);
					parent.array.insertInPlace(numeric, value);
				}
				catch(Exception e)
				{
					return error(parent.get.toString~" is array, index can't be "~index);
				}
				break;
			case JSON_TYPE.OBJECT:
				parent.get.object[index] = value;
				break;
			
			default: 
				return error(parent.get.toString ~ " is not array or object");
		}
		return true;
	}
}

class RemoveOperation : DiffOperation
{
	static emptyObject = parseJSON("{}");
	override @property string op() pure const @safe { return "remove"; }
	
	this(T)(T path) @safe
	{
		super(path);
	}

	override bool applyToPtr(JsonItem* document) const
	{
		if(path.isRoot)
		{
			*document = emptyObject;
			return true;
		}
		
		if(path.evaluate(document).isNull)
			return error("No path "~path.toString~" to remove");
			
		auto parent = path.parent.evaluate(document);
		string index = path.lastComponent;
		
		switch(parent.type)
		{
			case JSON_TYPE.ARRAY:
				try 
				{
					import std.array: replaceInPlace;
					
					auto numeric = index.to!int;
					if(numeric >= parent.array.length)
						return error("Too big index for "~parent.get.toString~", length="~parent.array.length.to!string);
					parent.array.replaceInPlace(numeric, numeric+1, cast(JsonItem[])[]);
				}
				catch(Exception e)
				{
					return error(parent.get.toString~" is array, index can't be "~index);
				}
				break;
			case JSON_TYPE.OBJECT:
				parent.get.object.remove(index);
				break;
			
			default: return error(parent.get.toString ~ " is not array or object");
		}
		return true;
	}

}

class ReplaceOperation : AddOperation
{
	override @property string op() pure const @safe { return "replace"; }
	
	this(string path, JsonItem value) @safe
	{
		super(path, value);
	}
	
	override bool applyToPtr(JsonItem* document) const
	{
		auto remove = scoped!RemoveOperation(path);
		return remove.applyToPtr(document) && super.applyToPtr(document);
	}
}

class MoveOperation : CopyOperation
{
	override @property string op() pure const @safe { return "move"; }
	
	this(T1, T2)(T1 path, T2 from) @safe
	{
		super(path, from);
	}

	override bool applyToPtr(JsonItem* document) const
	{
		auto fromValue = from.evaluate(document);
		if(fromValue.isNull)
			return error("No path "~from.toString~" to move from");
		
		auto remove = scoped!RemoveOperation(from);
		auto add = scoped!AddOperation(path, *(fromValue.get));
		
		return remove.applyToPtr(document) && add.applyToPtr(document);
	}
}

class CopyOperation : DiffOperation
{
	JsonPointer from;
	string s_path;
	
	this(string path, JsonPointer from) @safe
	{
		super(path);
		this.from = from;
	}

	this(string path, string from) @safe
	{
		super(path);
		this.from = JsonPointer(from);
	}
	
	override @property string op() pure const @safe { return "copy"; }
	
	override JsonItem toJson() const
	{
		JsonItem retval = super.toJson;
		retval.object["from"] = JsonItem(from.toString);
		return retval;
	}
	
	override bool applyToPtr(JsonItem* document) const
	{
		auto fromValue = from.evaluate(document);
		if(fromValue.isNull)
			return error("No path "~from.toString~" to copy from");
		
		auto add = scoped!AddOperation(path, *(fromValue.get));
		
		return add.applyToPtr(document);
	}
}

class TestOperation : AddOperation
{
	this(string path, JsonItem value)
	{
		super(path, value);
	}
	override @property string op() pure const @safe { return "test"; }
	override bool applyToPtr(JsonItem* document) const
	{
		import std.typecons: Nullable;
		
		auto target = path.evaluate(document);
		return !target.isNull && *(target.get) == value;
	}
	
}

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
