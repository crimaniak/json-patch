module vision.json.patch.operation;

public import vision.json.patch.operation.add;
public import vision.json.patch.operation.copy;
public import vision.json.patch.operation.move;
public import vision.json.patch.operation.remove;
public import vision.json.patch.operation.replace;
public import vision.json.patch.operation.test;

import std.conv: to;

DiffOperation toOperation(ref const JsonItem item)
{
	if(item.type != JSON_TYPE.OBJECT || "op" !in item.object || item.object["op"].type != JSON_TYPE.STRING)
		throw new Exception("Incorrect operation item:" ~ item.to!string);
			
	auto o = item.object;
	
	if("path" !in o)
		throw new Exception("No path property");
		
	auto path = o["path"].str;
			
	switch(o["op"].str)
	{
		case "add":    return new     AddOperation(path, o["value"]);
		case "copy":   return new    CopyOperation(path, o["from"].str);
		case "move":   return new    MoveOperation(path, o["from"].str);
		case "remove": return new  RemoveOperation(path);
		case "replace":return new ReplaceOperation(path, o["value"]);
		case "test":   return new    TestOperation(path, o["value"]);
		default: throw new Exception("Unknown operation type:" ~ item.to!string); 		
	}
}
	
auto toOperations(ref const JsonItem patch)
{
	import std.algorithm: map;
	import std.array: array;
	
	if(patch.type != JSON_TYPE.ARRAY)
		throw new Exception("Json patch root must be array");
		
	return patch.array.map!toOperation;
}
