module vision.json.patch.operation.test;

import vision.json.patch.operation.add;

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
