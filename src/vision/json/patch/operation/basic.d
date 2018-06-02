module vision.json.patch.operation.basic;

public import vision.json.patch.commons;
public import vision.json.pointer;

class DiffOperation
{
	import std.typecons: Tuple;
	import std.range: InputRange;
	
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
		import std.json : toJSON, JSONOptions;
		
		auto json = toJson;
		return json.toJSON(false, JSONOptions.doNotEscapeSlashes);
	}
	
	static bool error(string errorMessage)
	{
		lastError = errorMessage;
		return false;
	}
}
