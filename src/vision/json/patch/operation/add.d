module vision.json.patch.operation.add;

public import vision.json.patch.operation.basic;

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
		import std.conv : to;
		
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