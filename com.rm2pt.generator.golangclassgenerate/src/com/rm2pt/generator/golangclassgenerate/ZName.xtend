package com.rm2pt.generator.golangclassgenerate

import net.mydreamy.requirementmodel.rEMODEL.TypeCS
import java.util.List
import net.mydreamy.requirementmodel.rEMODEL.EnumEntity
import java.util.ArrayList
import net.mydreamy.requirementmodel.rEMODEL.Entity
import net.mydreamy.requirementmodel.rEMODEL.PrimitiveTypeCS
import net.mydreamy.requirementmodel.rEMODEL.EntityType
import java.util.TreeMap
import java.util.Collection

class ZName {
	public String originName;
	public String underline;
	public String initialLow;
	new(String originName) {
		this.originName = originName;
		underline = Tool.camelToUnderScore(originName);
		initialLow = Tool.firstLowerCase(originName);
	}
}




class ZBasicType {
	public String goName;
	public String sqlName;
	public String sqlConstraint;	
	public String goImport;
	new(String type) {
		goName = Tool.compileGoTypeName(type);
		goImport = Tool.compileGoImport(type);
		sqlName = Tool.compileSqlTypeName(type);
		sqlConstraint = Tool.compileSqlBasicConstraint(type);
	}
}

class ZEnumType {
	public String goName;
	public List<String> memberName = new ArrayList<String>();
	new(EnumEntity enumType){
		goName = enumType.name;
		for(e : enumType.element){
			memberName.add(enumType.name+e.name);
		}
	}	
}

class ZBasicField {
	public ZName member;
	public ZBasicType type;
	new(String attrName, String typeName) {
		member = new ZName(attrName);
		type = new ZBasicType(typeName);
	}
}
class ZEnumField {
	public ZName member;
	public ZEnumType type;
	new(String attrName, EnumEntity enumType) {
		member = new ZName(attrName);
		type = new ZEnumType(enumType);
	}
}

class ZSingleAss{
	public String originName;
	public ZName  field;
	public ZName  targetEntity;
	new(String originName, String targetEntityName){
		this.originName = originName;
		this.field = new ZName(originName+"GoenId");
		this.targetEntity = new ZName(targetEntityName);
	}
}

class ZMultiAss{
	public String originName;
	public String  tableName;
	public ZName  targetEntity;
	new(String originName, String ownerEntityName, String targetEntityName){
		this.originName = originName;
		this.tableName = Tool.camelToUnderScore(ownerEntityName) + "_" + Tool.camelToUnderScore(originName);
		this.targetEntity = new ZName(targetEntityName);
	}
}

class ZEntity  {
	public ZName entityName;
	public List<ZBasicField> basicFields = new ArrayList<ZBasicField>();
	public List<ZEnumField>  enumFields = new ArrayList<ZEnumField>();
	public List<ZSingleAss>  singleAsses = new ArrayList<ZSingleAss>();
	public List<ZMultiAss> multiAsses = new ArrayList<ZMultiAss>();
	public boolean isBaseEntity = false;
	public ZName parentEntity;
}

class ZEntityFactory{
	static def Collection<ZEntity> generateZEntities(Collection<Entity> entities) {
		var zEntities = new TreeMap<String, ZEntity>();
		// 第一遍
		System.out.println("第一遍,现在的entities:");
//		System.out.println(entities);
		for(e : entities){
			var ze = new ZEntity();
			ze.entityName = new ZName(e.name);
			for(a : e.attributes) {
				switch(a.type) {
					PrimitiveTypeCS: {
						ze.basicFields.add(new ZBasicField(a.name, (a.type as PrimitiveTypeCS).name));
					}
					EnumEntity:{
						ze.enumFields.add(new ZEnumField(a.name, a.type as EnumEntity));
					}
//					EntityType:{
//						System.out.println("entityType!!!!!");
//						if(!a.ismultiple){
//							ze.singleAsses.add(new ZSingleAss(a.name, (a.type as EntityType).entity.name));
//						}else{
//							ze.multiAsses.add(new ZMultiAss(a.name, (a.type as EntityType).entity.name));
//						}	
//					}
				}
			}
			for(a : e.reference) {	
				if(!a.ismultiple){
					ze.singleAsses.add(new ZSingleAss(a.name, a.entity.name));
				}else{
					ze.multiAsses.add(new ZMultiAss(a.name, e.name, a.entity.name));
				}	
			}
			zEntities.put(e.name ,ze);
		}
		// 第二遍
		System.out.println("第二遍,现在的entities:");
		System.out.println(entities);
		for(e : entities){
//			System.out.print("e.superEntity :");
//			System.out.println(e);
			if(e.superEntity !== null){
//				System.out.println("我进来楼");
				zEntities.get(e.superEntity.name).isBaseEntity = true;
				zEntities.get(e.name).parentEntity = new ZName(e.superEntity.name);
			}
		}
		return zEntities.values();
	}
	
}






