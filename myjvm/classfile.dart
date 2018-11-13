library myjvm.classfile;
//converted from classfile.d
//See https://docs.oracle.com/javase/specs/jvms/se7/html/jvms-4.html
import 'dart:typed_data';
import 'dart:convert';

///class that wraps ByteData
///the term Stream is overused but it fits here
class ByteDataOutputStream {
	ByteData _data;
	int _position=0;
	//constructor
	ByteDataOutputStream(ByteData bd) {_data=bd;}

	//methods
	//read unsigned byte
	int readUByte() {
		int ubyte=_data.getUint8(_position);
		_position=_position+1;
		return ubyte;
	}
	//read unsigned 16-bit
	int readUShort() {
		int ushort=_data.getUint16(_position);
		_position=_position+2;
		return ushort;
	}	
	int readUInt() {
		int uint=_data.getUint32(_position);
		_position=_position+4;
		return uint;
	}	
	int readInt() {
		int sint=_data.getInt32(_position);
		_position=_position+4;
		return sint;		
	}
	//Dart doesn't have casting so this will do the trick
	//read int relative to the current position. 
	//doesnt update _position
	//usually you will use -4 or +4 as argument
	int peekInt(int rp) {
		return _data.getInt32(_position+rp);
	}
	double peekFloat(int rp) {
		return _data.getFloat32(_position+rp);
	}	
	int peekLong(int rp) {
		return _data.getInt64(_position+rp);
	}
	double peekDouble(int rp) {
		return _data.getFloat64(_position+rp);
	}		
}

class ClassFile {
    //the magic number is 3405691582 (0xCAFEBABE)
    int             magic;
    int             minor_version;
    int             major_version;
    int             constant_pool_count;
    //cp_info[constant_pool_count-1] constant_pool;
    //The constant_pool table is indexed from 1 to constant_pool_count-1
    //cp_info[]      constant_pool;
    //List<cp_info>   constant_pool;
    List	    	constant_pool;	//array of cp_info
    int             access_flags;
    int             this_class;
    int             super_class;
    int             interfaces_count;
    //u2[interfaces_count] interfaces;
    //int[]           interfaces;
    List<int>	    interfaces;
    int             fields_count;
    //field_info[fields_count] fields;
    //field_info[] fields;
    //List<field_info>	fields;
    List	    	fields;		//array of field_info
    int             methods_count;
    //method_info[methods_count] methods;
    //method_info[] methods;
    //List<method_info>  methods;
    List	    	methods;		//array of method_info
    int             attributes_count;
    //attribute_info[attributes_count] attributes;
    //attribute_info[] attributes;
    //List<attribute_info>  attributes;
    List	    	attributes;
}

//access flags are one of these
const ACC_PUBLIC =              0x0001;
const ACC_PRIVATE =             0x0002;
const ACC_PROTECTED =           0x0004;
const ACC_STATIC =              0x0008;
const ACC_FINAL =               0x0010;
const ACC_SYNCHRONIZED =        0x0020;
const ACC_SUPER =               0x0020;
const ACC_VOLATILE =            0x0040;
const ACC_TRANSIENT =           0x0080;
const ACC_NATIVE =              0x0100;
const ACC_INTERFACE =           0x0200;
const ACC_ABSTRACT =            0x0400;
const ACC_MIRANDA =             0x0800;
const ACC_SYNTHETIC =           0x1000;
const ACC_ANNOTATION =          0x2000;
const ACC_ENUM =                0x4000;

//-----------------------------------
//constant pool
//struct cp_info {
//    u1 tag;
//    u1[] info;
//}

//I think an interface is better than a base class here
abstract class cp_info {
    int type();
    //after the tag has been read in, load the rest of the cp_info item
    //load self from buffer
    void load(ByteDataOutputStream buffer);
}

//tag is one of these
const CONSTANT_Utf8 =                   1;
const CONSTANT_Integer =                3;
const CONSTANT_Float =                  4;
const CONSTANT_Long =                   5;
const CONSTANT_Double =                 6;
const CONSTANT_Class =                  7;
const CONSTANT_String =                 8;
const CONSTANT_Fieldref =               9;
const CONSTANT_Methodref =              10;
const CONSTANT_InterfaceMethodref =     11;
const CONSTANT_NameAndType =            12;
const CONSTANT_MethodHandle =           15;
const CONSTANT_MethodType =             16;
const CONSTANT_InvokeDynamic =          18;

class CONSTANT_Class_info implements cp_info {
//The tag item has the value CONSTANT_Class (7).
	int tag;
    int name_index;
    String cname;
    int type() {return tag;}
    //after the tag has been read in, load the rest of the cp_info item
    void load(ByteDataOutputStream buffer) {
    	//name_index=buffer.read!ushort();
    	name_index=buffer.readUShort();
    }
}

class CONSTANT_ref_info implements cp_info {
	//The tag item of a CONSTANT_Fieldref_info structure has the value CONSTANT_Fieldref (9).
	//The tag item of a CONSTANT_Methodref_info structure has the value CONSTANT_Methodref (10).
	//The tag item of a CONSTANT_InterfaceMethodref_info structure has the value
	//	CONSTANT_InterfaceMethodref (11).
	//other than that, they have the same structure
	int tag;
    int class_index;
    int name_and_type_index;
    String cname;
    String name;
    String descriptor;
    
    int type() {return tag;}
    void load(ByteDataOutputStream buffer) {
    	class_index=buffer.readUShort();
    	name_and_type_index=buffer.readUShort();
    }    
}

class CONSTANT_String_info implements cp_info {
	//The tag item of the CONSTANT_String_info structure has the value CONSTANT_String (8).
	int tag;
    int string_index;
    String strval;	
    int type() {return tag;}
    void load(ByteDataOutputStream buffer) {
    	string_index=buffer.readUShort();
    }
}

class CONSTANT_Integer_info implements cp_info {
	//The tag item of the CONSTANT_Integer_info structure has the value CONSTANT_Integer (3).
	int tag;		//u1
    int bytes;  	//u4 this has the raw unsigned bytes
    int ival; 		//i4 this is signed
    int type() {return tag;}
    void load(ByteDataOutputStream buffer) {
    	bytes=buffer.readUInt();
    	//re-read the last 4 bytes as a signed int
    	ival=buffer.peekInt(-4);
    }
}

class CONSTANT_Float_info implements cp_info {
	//The tag item of the CONSTANT_Float_info structure has the value CONSTANT_Float (4).
	int tag;	//u1 tag;
    //The bytes item of the CONSTANT_Float_info structure represents the value of the float constant 
    //in IEEE 754 floating-point single format (2.3.2). The bytes of the single format representation
    //are stored in big-endian (high byte first) order.
    int bytes;		//u4 bytes;
    double fval;	//float fval;
    
    int type() {return tag;}    
    void load(ByteDataOutputStream buffer) {
    	//there must be a better way to do this but as long as it works...
    	//fval = buffer.peek!(float, Endian.bigEndian);
    	//bytes=buffer.read!uint();
    	bytes=buffer.readUInt();
    	fval=buffer.peekFloat(-4);
    }    
}

class CONSTANT_Long_info implements cp_info {
	//The tag item of the CONSTANT_Long_info structure has the value CONSTANT_Long (5).
	int tag;		//u1 tag;
    int high_bytes;	//u4 high_bytes;
    int low_bytes;	//u4 low_bytes;
    int lval;		//long lval;
    int type() {return tag;}    
    void load(ByteDataOutputStream buffer) {
    	//there must be a better way to do this but as long as it works...
    	//lval = buffer.peek!(long, Endian.bigEndian);
    	//high_bytes=buffer.read!uint();
    	//low_bytes=buffer.read!uint();
    	high_bytes=buffer.readUInt();
    	low_bytes=buffer.readUInt();
    	lval=buffer.peekLong(-8);
    }        
}

class CONSTANT_Double_info implements cp_info {
	//The tag item of the CONSTANT_Double_info structure has the value CONSTANT_Double (6).
	int tag;
    int high_bytes;
    int low_bytes;
    double dval;
    int type() {return tag;} 
    void load(ByteDataOutputStream buffer) {
    	//there must be a better way to do this but as long as it works...
    	high_bytes=buffer.readUInt();
    	low_bytes=buffer.readUInt();
    	dval=buffer.peekDouble(-8);
    }       
}

class CONSTANT_NameAndType_info implements cp_info {
	//The tag item of the CONSTANT_NameAndType_info structure has the value CONSTANT_NameAndType (12).
	int tag;		//u1 tag;
    int name_index;	//u2
    int descriptor_index;	//u2
    String name;
    String descriptor;	
    int type() {return tag;} 
    void load(ByteDataOutputStream buffer) {
    	name_index=buffer.readUShort();
    	descriptor_index=buffer.readUShort();
    }
}

class CONSTANT_Utf8_info implements cp_info {
	//The tag item of the CONSTANT_Utf8_info structure has the value CONSTANT_Utf8 (1).
    int tag;	//u1
    int length;	//u2
    //u1 bytes[length];
    //u1[] bytes;
    List<int> bytes;
    String utf8;
    int type() {return tag;} 
    //void load(ref ubyte[] buffer) {  
    //	length=buffer.read!ushort();
    //	assert(length>0);
    //	bytes=new ubyte[length];
    //	for (int i=0;i<length;i++) {
    //		bytes[i]=buffer.read!ubyte();
    //	}
    //	utf8=bytes.assumeUTF;
    //	assert(utf8!=null);
    //}
    //this is a little complicated
    //we need to read in the specified number of bytes
    //then create a string out of it
    void load(ByteDataOutputStream buffer) {
    	length=buffer.readUShort();
    	bytes=new List(length);
    	for (int i=0;i<length;i++) {
    		int by=buffer.readUByte();
    		bytes[i]=by;
    	}
    	utf8 = new Utf8Codec().decode(bytes); 
    }
}

//I don't expect to use this but it is defined in the spec
class CONSTANT_MethodHandle_info implements cp_info {
	//The tag item of the CONSTANT_MethodHandle_info structure has the value CONSTANT_MethodHandle (15).
    int tag;
    int reference_kind;	//u1
    int reference_index;	//u2
    int type() {return tag;}   
    void load(ByteDataOutputStream buffer) {
    	reference_kind=buffer.readUByte();
    	reference_index=buffer.readUShort();
    }
}

class CONSTANT_MethodType_info implements cp_info {
	//The tag item of the CONSTANT_MethodType_info structure has the value CONSTANT_MethodType (16).
    int tag;
    int descriptor_index;
    int type() {return tag;} 
    void load(ByteDataOutputStream buffer) {
    	descriptor_index=buffer.readUShort();
    }    
}

class CONSTANT_InvokeDynamic_info implements cp_info {
	//The tag item of the CONSTANT_InvokeDynamic_info structure has the value CONSTANT_InvokeDynamic (18).
    int tag;
    int bootstrap_method_attr_index;
    int name_and_type_index;
    int type() {return tag;}   
    void load(ByteDataOutputStream buffer) {
    	bootstrap_method_attr_index=buffer.readUShort();
    	name_and_type_index=buffer.readUShort();
    }       
}
//end constant pool
//-----------------------------------------------

class field_info {
    int            access_flags;	//u2
    bool		   isStatic;
    int             name_index;		//u2
    String 		   fname;
    int             descriptor_index;	//u2
    String 		   descriptor;
    int             attributes_count;	//u2
    //attribute_info[attributes_count] attributes;
    //attribute_info[] attributes;
    List	    	attributes;
    //if the field is static, then this will hold the value
    //it should be of type Variable, but I don't want to hard-code it
    Object			static_value;
}

class method_info {
    int             access_flags;
    bool		   isStatic;
    int            name_index;
    String         mname;
    int             descriptor_index;
    String         descriptor;    
    int             attributes_count;
    //attribute_info[attributes_count] attributes;
    //attribute_info[] attributes;
    List attributes;
    //ubyte[] code;
    List<int> code;
}

//--------------------------------------
//attributes

//each attribute_info has a 6 byte header.  The index is to the attribute_name, which is stored as
//utf8 like "ConstantValue", "Code" etc
//I prefer not to use inheritance but it fits here.  There are 10 classes that extend this
abstract class attribute_info {
	int attribute_name_index;	//u2
	String aname;
	int attribute_length;		//u4
	//constructor
	attribute_info(int name_index,String name,int length) {
		attribute_name_index=name_index;
		aname=name;
		attribute_length=length;
	}
	int index() {return attribute_name_index;}
	String attr_name() {return aname;}
	//The value of the attribute_length item indicates the length of the subsequent information in bytes. 
	//The length does not include the initial six bytes that contain the attribute_name_index and attribute_length items.
	int length() {return attribute_length;}

	//after the index and length have been read in, read in the rest of the attribute_info
	void load(ByteDataOutputStream buffer);
}

//I'm not going to define all of these, just the most common ones
class ConstantValue_attribute extends attribute_info {
    int constantvalue_index;
    ConstantValue_attribute(int name_index,String name,int length) : super(name_index,name,length);
	void load(ByteDataOutputStream buffer) {
		constantvalue_index=buffer.readUShort();
	}
}

class Code_attribute extends attribute_info {
    //u2 attribute_name_index;
    //string aname;
    //u4 attribute_length;
    int max_stack;	//u2
    int max_locals;	//u2
    int code_length;	//u4
    List<int> code;
	int exception_table_length;	//u2
    //exception_table_entry[] exception_table;
    List exception_table;
    //nested attributes
    int attributes_count;	//u2
    //attribute_info attributes[attributes_count];
    //attribute_info[] attributes;
    List attributes;
    //-------------------------
    Code_attribute(int name_index,String name,int length) : super(name_index,name,length);
    
    //the default load, which we don't use
    void load(ByteDataOutputStream buffer) {}
    
    //here is our method
    //void load_code(ref ubyte[] buffer,cp_info[] pool) {
    void load_code(ByteDataOutputStream buffer,List pool) {
		max_stack=buffer.readUShort();
		max_locals=buffer.readUShort();
		code_length=buffer.readUInt();
		//code=new ubyte[code_length];
		code = new List(code_length);
		//is there a faster way of reading this in?
		for (int i=0;i<code_length;i++) {
			//code[i]=buffer.read!ubyte();
			code[i]=buffer.readUByte();
		}
		exception_table_length=buffer.readUShort();
		if (exception_table_length>0) {
			//I don't know if this is necessary, but it makes it clear that you can skip this if length is 0
			//exception_table=new exception_table_entry[exception_table_length];
			exception_table=new List(exception_table_length);
			for (int i=0;i<exception_table_length;i++) {
				exception_table_entry x=new exception_table_entry();
				x.start_pc=buffer.readUShort();
				x.end_pc=buffer.readUShort();
				x.handler_pc=buffer.readUShort();
				x.catch_type=buffer.readUShort();
				exception_table[i]=x;
			}
		}
		
		//holy crap there are nested attributes?
		//The only attributes defined by this specification as appearing in the attributes table of a Code 
		//attribute are the LineNumberTable (4.7.12), LocalVariableTable (4.7.13), 
		//LocalVariableTypeTable (4.7.14), and StackMapTable (4.7.4) attributes.
		//I don't care about these right now
		attributes_count=buffer.readUShort();
		if (attributes_count>0) {
			//attributes = new attribute_info[attributes_count];
			attributes = new List(attributes_count);
		
			for (int j=0;j<attributes_count;j++) {
				int gnidx=buffer.readUShort();
				//CONSTANT_Utf8_info u=cast(CONSTANT_Utf8_info)pool[gnidx];
				CONSTANT_Utf8_info u=pool[gnidx];
				String gname=u.utf8;
				print("DEBUG: attribute name=" + gname);
				int glen=buffer.readUInt();	//u4
				if (gname == "LineNumberTable") {
					print("DEBUG: creating LineNumberTable attribute");
					LineNumberTable_attribute lnt=new LineNumberTable_attribute(gnidx,gname,glen);
					lnt.load(buffer);
					attributes[j]=lnt;
				} else {	
					print("DEBUG: NOT creating " + gname + " attribute");
					Generic_attribute g=new Generic_attribute(gnidx,"Generic",glen);
					g.load(buffer);
					attributes[j]=g;
				}
			}
		} //end if
	} //end load_code
}

class exception_table_entry {
	int start_pc;	//all u2
    int end_pc;
    int handler_pc;
    int catch_type;
}

//this is a placeholder for attributes that I don't care about but have to deal with
class Generic_attribute extends attribute_info {
    //u2 attribute_name_index;
    //string aname;
    //u4 attribute_length;
    List<int> garbage;	//u1[]
    //-------------------------
    Generic_attribute(int name_index,String name,int length) : super(name_index,name,length);
       
	void load(ByteDataOutputStream buffer) {
		if (attribute_length>0) {
			garbage=new List(attribute_length);
			for (int k=0;k<attribute_length;k++) {
				garbage[k]=buffer.readUByte();
			}
		}
	}
}

//4.7.4. The StackMapTable Attribute
//we don't use this

class Exceptions_attribute extends attribute_info {
    int number_of_exceptions;	//u2
    //Each value in the exception_index_table array must be a valid index into the constant_pool table.
    //The constant_pool entry referenced by each table item must be a CONSTANT_Class_info structure (4.4.1) 
    //representing a class type that this method is declared to throw.
    //u2[] exception_index_table;
    List<int> exception_index_table;
    //---------------------
    Exceptions_attribute(int name_index,String name,int length) : super(name_index,name,length);
     

	void load(ByteDataOutputStream buffer) {
		number_of_exceptions=buffer.readUShort();
		//assert(number_of_exceptions>0);
		//exception_index_table=new ushort[number_of_exceptions];
		exception_index_table=new List(number_of_exceptions);
		for (int i=0;i<number_of_exceptions;i++) {
			exception_index_table[i]=buffer.readUShort();
		}
	}
}

//4.7.6. The InnerClasses Attribute
class InnerClasses_attribute extends attribute_info {
    int number_of_classes;
    //inner_class_info[] classes;
    List classes;	
    InnerClasses_attribute(int name_index,String name,int length) : super(name_index,name,length);
        
   
	void load(ByteDataOutputStream buffer) {
		number_of_classes=buffer.readUShort();
		//assert(number_of_classes>0);
		//classes=new inner_class_info[number_of_classes];
		classes=new List(number_of_classes);
		for (int i=0;i<number_of_classes;i++) {
			inner_class_info k=new inner_class_info();
			k.inner_class_info_index=buffer.readUShort();
			k.outer_class_info_index=buffer.readUShort();
			k.inner_name_index=buffer.readUShort();
			k.inner_class_access_flags=buffer.readUShort();
			classes[i]=k;
		}
	}
}

class inner_class_info {
	int inner_class_info_index;	//u2
    int outer_class_info_index;	//u2
    int inner_name_index;		//u2
    int inner_class_access_flags;	//u2
}

class EnclosingMethod_attribute extends attribute_info {
    int class_index;
    int method_index;
    EnclosingMethod_attribute(int name_index,String name,int length) : super(name_index,name,length);
           
	void load(ByteDataOutputStream buffer) {
		class_index=buffer.readUShort();
		method_index=buffer.readUShort();
	}
}

//this has nothing except for the name
//for synthetic, The value of the attribute_length item is zero.
class Synthetic_attribute extends attribute_info {
    Synthetic_attribute(int name_index,String name,int length) : super(name_index,name,length);
         
	void load(ByteDataOutputStream buffer) {
		//nothing to do, synthetic is just a marker
	}
}

class Signature_attribute extends attribute_info {
    int signature_index;
    Signature_attribute(int name_index,String name,int length) : super(name_index,name,length);
        

	void load(ByteDataOutputStream buffer) {
		signature_index=buffer.readUShort();
	}
}

class SourceFile_attribute extends attribute_info {
    //u2 attribute_name_index;
    //string aname;
    //u4 attribute_length;
    int sourcefile_index;	//u2
    SourceFile_attribute(int name_index,String name,int length) : super(name_index,name,length);
         

	void load(ByteDataOutputStream buffer) {
		sourcefile_index=buffer.readUShort();
	}
}

//4.7.11. The SourceDebugExtension Attribute
//I'm skipping this

//LineNumberTable attribute is part of the code attribute
//It may be used by debuggers to determine which part of the Java Virtual Machine code array 
//corresponds to a given line number in the original source file.

class LineNumberTable_attribute extends attribute_info {
    int line_number_table_length;	//u2
    //line_number_info[] line_number_table;
    List line_number_table;
    LineNumberTable_attribute(int name_index,String name,int length) : super(name_index,name,length);
          
	void load(ByteDataOutputStream buffer) {
		line_number_table_length=buffer.readUShort();
		print("DEBUG: line_number_table_length="+ "$line_number_table_length");
		if (line_number_table_length>0) {
			//line_number_table=new line_number_info[line_number_table_length];
			line_number_table=new List(line_number_table_length);
			for (int i=0;i<line_number_table_length;i++) {
				line_number_info lni=new line_number_info();
				lni.start_pc=buffer.readUShort();
				lni.line_number=buffer.readUShort();
				line_number_table[i]=lni;
			}
		}
	}
}

class line_number_info {
	int start_pc;
    int line_number;	
}

//class LocalVariableTable_attribute : attribute_info {
//    u2 attribute_name_index;
//    u4 attribute_length;
//    u2 local_variable_table_length;
//    local_variable_info[] local_variable_table;
//    u2 index() {return attribute_name_index;}
//    u4 length() {return attribute_length;}     
//}

//struct local_variable_info {
//	u2 start_pc;
//    u2 length;
//    u2 name_index;
//    u2 descriptor_index;
//    u2 index;
//}

//class LocalVariableTypeTable_attribute : attribute_info {
//    u2 attribute_name_index;
//    u4 attribute_length;
//    u2 local_variable_type_table_length;
//    local_variable_type_info[] local_variable_type_table;
//    u2 index() {return attribute_name_index;}
//    u4 length() {return attribute_length;}  
//}

//struct local_variable_type_info {
//	u2 start_pc;
//    u2 length;
//    u2 name_index;
//    u2 signature_index;
//    u2 index;
//}

//for deprecated, The value of the attribute_length item is zero.
class Deprecated_attribute extends attribute_info {
    Deprecated_attribute(int name_index,String name,int length) : super(name_index,name,length);
      
	void load(ByteDataOutputStream buffer) {
		//nothing to do, deprecated is just a marker
	}
}

//4.7.16. The RuntimeVisibleAnnotations attribute
//4.7.16.1. The element_value structure
//4.7.17. The RuntimeInvisibleAnnotations attribute
//4.7.18. The RuntimeVisibleParameterAnnotations attribute
//4.7.19. The RuntimeInvisibleParameterAnnotations attribute
//4.7.20. The AnnotationDefault attribute
//4.7.21. The BootstrapMethods attribute
//not used