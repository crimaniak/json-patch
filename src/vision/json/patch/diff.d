module vision.json.patch.diff;

import std.conv: to;
import vision.json.patch.commons;
import vision.json.patch.operation;


/**
 * Generate diff between two Json documents
 * Naive implementation without any optimization
 */
DiffOperation[] diff(const ref JsonItem source, const ref JsonItem target,
                           const string path = "")
{ 
    DiffOperation[] result;

    if (source == target)
        return result;

    if (source.type() != target.type())
        result ~= new ReplaceOperation(path, target);
    else
        switch (source.type())
        {
            case JSON_TYPE.ARRAY:
                int i = 0;
                while (i < source.array.length && i < target.array.length)
                {
                    result ~= diff(source[i], target[i], path ~ "/" ~ i.to!string);
                    ++i;
                }

                DiffOperation[] removes;
                while (i < source.array.length)
                {
                    removes ~= new RemoveOperation(path ~ "/" ~ i.to!string);
                    ++i;
                }
                
                import std.range: retro;
                import std.array: array;
                
                result ~= removes.retro.array;

                while (i < target.array.length)
                {
                	result ~= new AddOperation(path ~ "/" ~ i.to!string, target[i]);
                    ++i;
                }
                break;

            case JSON_TYPE.OBJECT:
                foreach (key, ref value; source.object)
                    if (key in target.object)
                        result ~= diff(value, target.object[key], path ~ "/" ~ key);
                    else
                        result ~= new RemoveOperation(path ~ "/" ~ key);

                foreach (key, ref value; target.object)
                    if (key !in source.object)
                        result ~= new AddOperation(path ~ "/" ~ key, value);

                break;

            default:
                result ~= new ReplaceOperation(path, target);
                break;
        }

    return result;
}

JsonItem toJson(DiffOperation[] d)
{
	import std.json;
	import std.algorithm: map, each;
	
	int[] emptyArray;
	auto output = JsonItem(emptyArray);
	
	d.map!(op => op.toJson).each!(op => output.array ~= op);
	
	return output;
	
}
