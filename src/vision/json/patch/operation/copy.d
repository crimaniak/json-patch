module vision.json.patch.operation.copy;

public import vision.json.patch.operation.basic;

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
		import std.typecons : scoped;
		import vision.json.patch.operation.add : AddOperation;
		
		auto fromValue = from.evaluate(document);
		if(fromValue.isNull)
			return error("No path "~from.toString~" to copy from");
		
		auto add = scoped!AddOperation(path, *(fromValue.get));
		
		return add.applyToPtr(document);
	}
}
