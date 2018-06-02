module vision.json.patch.operation.move;

import vision.json.patch.operation.copy : CopyOperation, JsonItem;

class MoveOperation : CopyOperation
{
	
	override @property string op() pure const @safe { return "move"; }
	
	this(T1, T2)(T1 path, T2 from) @safe
	{
		super(path, from);
	}

	override bool applyToPtr(JsonItem* document) const
	{
		import std.typecons : scoped;
		import vision.json.patch.operation.remove : RemoveOperation;
		import vision.json.patch.operation.add : AddOperation;

		
		auto fromValue = from.evaluate(document);
		if(fromValue.isNull)
			return error("No path "~from.toString~" to move from");
		
		auto remove = scoped!RemoveOperation(from);
		auto add = scoped!AddOperation(path, *(fromValue.get));
		
		return remove.applyToPtr(document) && add.applyToPtr(document);
	}
}
