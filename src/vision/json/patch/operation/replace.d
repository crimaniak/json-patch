module vision.json.patch.operation.replace;

import vision.json.patch.operation.add;

class ReplaceOperation : AddOperation
{
	override @property string op() pure const @safe { return "replace"; }
	
	this(string path, JsonItem value) @safe
	{
		super(path, value);
	}
	
	override bool applyToPtr(JsonItem* document) const
	{
		import std.typecons : scoped;
		import vision.json.patch.operation.remove : RemoveOperation;
		
		auto remove = scoped!RemoveOperation(path);
		return remove.applyToPtr(document) && super.applyToPtr(document);
	}
}