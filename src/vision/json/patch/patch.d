module vision.json.patch.patch;

import vision.json.patch.operation;

bool patchInPlace(ref JsonItem document, ref const JsonItem patch)
{
	foreach(op; patch.toOperations)
		if(!op.applyTo(document))
			throw new Exception(op.lastError);
			
	return true;
}  
