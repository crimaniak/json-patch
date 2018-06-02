[![Build Status](https://travis-ci.org/crimaniak/json-patch.svg)](https://travis-ci.org/crimaniak/json-patch)
[![codecov](https://codecov.io/gh/crimaniak/json-patch/branch/master/graph/badge.svg)](https://codecov.io/gh/crimaniak/json-patch)
[![license](https://img.shields.io/github/license/crimaniak/json-patch.svg)](https://github.com/crimaniak/json-patch/blob/master/LICENSE)

# JavaScript Object Notation (JSON) Patch

This is implementation of [rfc6902](https://tools.ietf.org/html/rfc6902).

JSON Patch defines a JSON document structure for expressing a sequence of operations to apply to a JavaScript Object Notation (JSON) document.

library functionality: 

* generate diff between two documents
* patch in place document using generated patch

 Json document format accepted: [JSONValue](https://dlang.org/phobos/std_json.html#.JSONValue)

### Interface
```D
    alias JsonItem = JSONValue;
    
    // diff part
    DiffOperation[] diff(const ref JsonItem source, const ref JsonItem target,
                           const string path = "");

	JsonItem toJson(DiffOperation[] d);
	
	// patch part
	
	bool patchInPlace(ref JsonItem document, ref const JsonItem patch);

```
### Usage

```D
	import vision.json.patch.commons;
	import vision.json.patch.diff;
	import vision.json.patch.patch;
    
	JsonItem source = ...;
	JsonItem target = ...;
		
	auto patch = diff(source.document, target.document).toJson;
		
	auto patched = source.document;
	patched.patchInPlace(patch);
		
	assert(patched == target)
    
```
