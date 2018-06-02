module vision.json.patch.operation.remove;

import vision.json.patch.operation.basic;

class RemoveOperation : DiffOperation
{
	import std.json : parseJSON;
	
	static emptyObject = parseJSON("{}");
	override @property string op() pure const @safe { return "remove"; }
	
	this(T)(T path) @safe
	{
		super(path);
	}

	override bool applyToPtr(JsonItem* document) const
	{
		import std.conv : to;
		
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