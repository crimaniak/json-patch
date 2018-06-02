module vision.json.patch.operation.basic;

public import vision.json.patch.commons;
public import vision.json.pointer;

 /**
  * Basic class for all diff operations
  */
class DiffOperation
{
	import std.typecons: Tuple;
	import std.range: InputRange;
	
	alias DataRange = InputRange!(Tuple!(string, const JsonItem));
	
	/// Error message for last failed operation 
	static string lastError;
	/// Path of element to affect
	const JsonPointer path;
	/// Operation name
	abstract @property string op() pure const @safe;
	
	/// Apply this operation to document
	bool applyTo(ref JsonItem document) const
	{
		return applyToPtr(&document);
	}
	
	/// Apply this operation to document by pointer
	abstract bool applyToPtr(JsonItem* document) const;
	
	this(const string path) @safe
	{
		this.path = JsonPointer(path);
	}
	
	this(const JsonPointer path) @safe
	{
		this.path = path;
	}
	
	/// Convert to Json element
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
	
	/// Return error and store error message
	static bool error(string errorMessage)
	{
		lastError = errorMessage;
		return false;
	}
}
