package com.rm2pt.generator.golangclassgenerate

import java.util.regex.Pattern
import net.mydreamy.requirementmodel.rEMODEL.PrimitiveTypeCS
import net.mydreamy.requirementmodel.rEMODEL.EnumEntity
import net.mydreamy.requirementmodel.rEMODEL.EntityType
import net.mydreamy.requirementmodel.rEMODEL.TypeCS
import org.eclipse.emf.ecore.resource.Resource
import java.util.ArrayList

class Tool {
	
	static def camelToUnderScore(String line){
		if(line===null||"".equals(line)){
		   return "";
	  }
	  var line2 = String.valueOf(line.charAt(0)).toUpperCase().concat(line.substring(1));
	  var sb=new StringBuffer();
	  var pattern=Pattern.compile("[A-Z]([a-z\\d]+)?");
	  var matcher=pattern.matcher(line2);
	  while(matcher.find()){
	   var word=matcher.group();
	   sb.append(word.toLowerCase());
	   sb.append(matcher.end()==line2.length()?"":"_");
	  }
	  return sb.toString();
	}
	static def camelToDivider(String line){
		if(line===null||"".equals(line)){
		   return "";
	  }
	  var line2 = String.valueOf(line.charAt(0)).toUpperCase().concat(line.substring(1));
	  var sb=new StringBuffer();
	  var pattern=Pattern.compile("[A-Z]([a-z\\d]+)?");
	  var matcher=pattern.matcher(line2);
	  while(matcher.find()){
	   var word=matcher.group();
	   sb.append(word.toLowerCase());
	   sb.append(matcher.end()==line2.length()?"":"-");
	  }
	  return sb.toString();
	}
	
	static def firstLowerCase(String name) {
		name.toLowerCase().substring(0,1) + name.substring(1)
	}
	static def firstUpperCase(String name){
		name.toUpperCase().substring(0,1) + name.substring(1)
	}
	
	static def compileGoTypeName(TypeCS type)
	{
		
		if (type !== null)
		{
			switch type {
				PrimitiveTypeCS : 
					switch type {
					case  type.name == "Boolean" : "bool"
					case  type.name == "String" : "string"
					case  type.name == "Real" : "float64"
					case  type.name == "Integer" : "int"
					case  type.name == "Date" : "time.Time"
					default: ""
				}
				EnumEntity : type.name
				EntityType : type.entity.name
				default: ""
			}
		}			
		else 
		{
			""
		}	
	}
	
	static def compileSqlType(TypeCS type) 
	{
		
		if (type !== null)
		{
			switch type {
				PrimitiveTypeCS : 
					switch type {
					case  type.name == "Boolean" : "bool"
					case  type.name == "String" : "varchar(255)"
					case  type.name == "Real" : "float"
					case  type.name == "Integer" : "int"
					case  type.name == "Date" : "datetime"
					default: ""
				}
				EnumEntity : "int"
				EntityType : type.entity.name
				default: ""
			}
		}			
		else 
		{
			""
		}	
	}
	static def compileSqlBasicConstraint(TypeCS type) 
	{
		
		if (type !== null)
		{
			switch type {
				PrimitiveTypeCS : 
					switch type {
					case  type.name == "Boolean" : "bool"
					case  type.name == "String" : "varchar(255)"
					case  type.name == "Real" : "float"
					case  type.name == "Integer" : "int"
					case  type.name == "Date" : "datetime"
					default: ""
				}
				EnumEntity : "int"
				EntityType : type.entity.name
				default: ""
			}
		}			
		else 
		{
			""
		}	
	}
	static def compileSqlBasicConstraint(String typeName) 
	{	
		switch typeName {
			
				case  "Boolean" : "not null default(false)"
				case  "String" : "not null default('')"
				case  "Real" : "not null default(0)"
				case  "Integer" : "not null default(0)"
				case  "Date" : "not null default('0001-01-01 00:00:00')"
				default: ""
		}			
	}
	
	static def compileGoTypeName(String typeName) 
	{	
		switch typeName {
			
				case  "Boolean" : "bool"
				case  "String" : "string"
				case  "Real" : "float64"
				case  "Integer" : "int"
				case  "Date" : "time.Time"
				default: typeName
		}			
	}
	static def compileGoImport(String typeName) 
	{	
		switch typeName {
				case  "Date" : "\"time\""
				default: null
		}			
	}
	
	static def compileSqlTypeName(String typeName) 
	{	
		switch typeName {
			
				case  "Boolean" : "boolean"
				case  "String" : "varchar(255)"
				case  "Real" : "double"
				case  "Integer" : "int"
				case  "Date" : "datetime"
				default: ""
		}			
	}
	static def removeComma(CharSequence str) {
		for(var i = str.length() - 1; i >= 0; i--){
//			System.out.printf("%c 和 %c", str.charAt(i) + "和" + ',');
			if (str.charAt(i).toString() == ','.toString()){
				return str.subSequence(0, i);
			}
		}
		return '''why last????''';
	}
}