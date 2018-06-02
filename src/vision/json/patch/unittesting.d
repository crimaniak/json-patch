module vision.json.patch.unittesting;

unittest
{
	import std.json;
	import vision.json.patch.commons;
	import vision.json.patch.diff;
	import vision.json.patch.patch;
	
	struct RandomDocument
	{
		import std.random;
		
		enum N = 1024;
		enum maxStringLength = 4;
		enum maxArrayLength = 10;
		enum maxObjectLength = 10;
		
		JsonItem document;
		auto rnd = Random(0);
		
		this(float deep, float reducer)
		{
			document = getRandomDocument(deep, reducer);
		}
		
		JsonItem getRandomDocument(float deep, float reducer) const
		{
			final switch(getRandomType(deep))
			{
				case JSON_TYPE.ARRAY:
					return getRandomArray(deep, reducer);
				case JSON_TYPE.FALSE:
					return parseJSON("false");
				case JSON_TYPE.FLOAT:
					return getRandomFloat();
				case JSON_TYPE.INTEGER:
					return getRandomInteger();
				case JSON_TYPE.NULL:
					return parseJSON("null");
				case JSON_TYPE.OBJECT:
					return getRandomObject(deep, reducer);
				case JSON_TYPE.STRING:
					return JsonItem(getRandomString());
				case JSON_TYPE.TRUE:
					return parseJSON("true");
				case JSON_TYPE.UINTEGER:
					return getRandomUinteger();
			}
		}
		
		JsonItem getRandomArray(float deep, float reducer) const
		{
			JsonItem[] a;
			for(auto i=uniform(1, maxArrayLength);--i>0;)
				a ~= getRandomDocument(deep-reducer, reducer);
			return JsonItem(a);	
		}

		JsonItem getRandomObject(float deep, float reducer) const
		{
			JsonItem[string] a;
			for(auto i=uniform(1, maxObjectLength);--i>0;)
				a[getRandomString()] = getRandomDocument(deep-reducer, reducer);
			return JsonItem(a);	
		}
		
		JsonItem getRandomFloat() const
		{
			return JsonItem(uniform(0.0f, 1e6));
		}

		JsonItem getRandomInteger() const
		{
			return JsonItem(uniform(int.min, int.max));
		}
		JsonItem getRandomUinteger() const
		{
			return JsonItem(uniform(0, int.max));
		}
		
		string getRandomString() const
		{
			string s;
			for(auto i = uniform(1, maxStringLength);--i;)
				s ~= uniform('a', 'z');
			return s;				
		}
		
		JSON_TYPE getRandomType(float deep) const
		{
			return (uniform(0, N) < deep*N/2) 
				? [JSON_TYPE.OBJECT, JSON_TYPE.ARRAY].choice() 
				: [JSON_TYPE.FALSE, JSON_TYPE.FLOAT,JSON_TYPE.INTEGER, JSON_TYPE.NULL, JSON_TYPE.STRING, JSON_TYPE.TRUE, JSON_TYPE.UINTEGER].choice();
		}
		
	}
	
	for(auto i=0; i<500; ++i)
	{
		auto source = RandomDocument(1.0, 0.2);
		auto target = RandomDocument(1.0, 0.2);
		
		auto patch = diff(source.document, target.document).toJson;
		
		auto patched = source.document;
		try
		{
			patched.patchInPlace(patch);
		
			if(patched != target.document)
				throw new Exception("Result incorrect");
		} 
		catch(Exception e)
		{
			import std.stdio;
			writeln("Fail:", e.msg);
			writeln(source.document);
			writeln(target.document);
			writeln(patched);
			writeln(patch);
			break;
		}
	}
}