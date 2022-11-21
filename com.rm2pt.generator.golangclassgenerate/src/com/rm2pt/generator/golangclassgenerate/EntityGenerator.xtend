package com.rm2pt.generator.golangclassgenerate

import net.mydreamy.requirementmodel.rEMODEL.*
import java.util.regex.Pattern
import java.util.TreeMap
import java.util.TreeSet
import java.util.Collection
import java.util.List
import java.util.ArrayList
import java.util.LinkedHashSet
import java.util.LinkedList
import java.util.HashMap

class EntityGenerator {
	static private def getInheritConsts(Collection<ZEntity> entities){
		var strList = new ArrayList<String>();
		for(e : entities){
			if(e.parentEntity!==null){
				strList.add(e.entityName.originName + "InheritType");
			}
		}
		return strList;
	}
	static def generateInit(Collection<ZEntity> entities){
		var inheritConsts = getInheritConsts(entities);
		var entityMap = new HashMap<String, ZEntity>();
		for(e : entities){
			entityMap.put(e.entityName.originName, e);
		}
		var sortedEntities = new LinkedHashSet<ZEntity>;
		for(e : entities){
			var nowe = e;
			var willAdd = new LinkedList<ZEntity>();
			willAdd.addFirst(nowe);
			while(nowe.parentEntity !== null){
				nowe = entityMap.get(nowe.parentEntity.originName);
				willAdd.addFirst(nowe);
			}
			for(eAdd : willAdd){
				sortedEntities.add(eAdd);
			}
		}
		return 
		'''
		package entity
		
		import (
			"Cocome/entityRepo"
			"log"
		)
		
		«IF inheritConsts.length() != 0»
		const (
			«inheritConsts.get(0)» entityRepo.GoenInheritType = iota + 1
			«FOR inheritConst : inheritConsts.subList(1, inheritConsts.length())»
			«inheritConst»
			«ENDFOR»
		)
		«ENDIF»
		
		func init() {
			«FOR e : sortedEntities»
			«IF e.parentEntity === null»
			tmp«e.entityName.originName»Repo, err := entityRepo.NewRepo[«e.entityName.originName»Entity, «e.entityName.originName»]("«e.entityName.underline»")			
			«ELSE»
			tmp«e.entityName.originName»Repo, err := entityRepo.NewInheritRepo[«e.entityName.originName»Entity, «e.entityName.originName»]("«e.entityName.underline»", tmp«e.parentEntity.originName»Repo, «e.entityName.originName»InheritType)			
			«ENDIF»
			if err != nil {
				log.Fatal(err)
			}
			«e.entityName.initialLow»Repo = tmp«e.entityName.originName»Repo
			«e.entityName.originName»Repo = tmp«e.entityName.originName»Repo
			«ENDFOR»
			
		}
		'''
	}
	
	static def generate(ZEntity entity){
		'''
		package entity
		
		«generateImport(entity)»
		«generateRepos(entity)»
		«generateEnum(entity)»
		«generateInterface(entity)»
		«generateStruct(entity)»
		«generateOtherImplements(entity)»
		«generateGetters(entity)»
		«generateSetters(entity)»
		'''
	}
	
	
	
	static def generateImport(ZEntity e) {
		var imports = new TreeSet<String>();
		for(a : e.basicFields){
			if(a.type.goImport!==null){
				imports.add(a.type.goImport);
			}
		}
		return
		'''
		import(
		"Cocome/entityRepo"
		«FOR i : imports»
		«i»
		«ENDFOR»
		)
		
		'''
	}
	static def generateRepos(ZEntity e) {
		'''
		var «e.entityName.initialLow»Repo entityRepo.RepoForEntity[«e.entityName.originName»]
		«IF e.isBaseEntity || e.parentEntity !== null»
		var «e.entityName.originName»Repo entityRepo.InheritRepoForOther[«e.entityName.originName»]
		«ELSE»
		var «e.entityName.originName»Repo entityRepo.RepoForOther[«e.entityName.originName»]
		«ENDIF»
		
		'''
	}

	static def generateEnum(ZEntity e) {
		'''
		«FOR a : e.enumFields»
		type «a.type.goName» int
		
		const (
			«a.type.memberName.get(0)» «a.type.goName» = iota
			«FOR member: a.type.memberName.subList(1, a.type.memberName.length())»
			«member»
			«ENDFOR»
		)
		«ENDFOR»
		
		'''
	}
	
	static private def generateGetterDeclares(ZEntity e){
		var strList = new ArrayList<String>();
		for(a : e.basicFields){
			strList.add('''Get«a.member.originName» () «a.type.goName» ''')
		}
		for(a : e.enumFields){
			strList.add('''Get«a.member.originName» () «a.type.goName» ''')
		}
		for(a : e.singleAsses){
			strList.add('''Get«a.originName» () «a.targetEntity.originName» ''')
		}
		for(a : e.multiAsses){
			strList.add('''Get«a.originName» () []«a.targetEntity.originName» ''')
		}
		return strList;
	}
	static private def generateGetterBodies(ZEntity e){
		var strList = new ArrayList<String>();
		for(a : e.basicFields){
			strList.add('''return p.«a.member.originName» ''')
		}
		for(a : e.enumFields){
			strList.add('''return p.«a.member.originName» ''')
		}
		for(a : e.singleAsses){
			strList.add(
			'''
			if p.«a.field.originName» == nil {
				return nil
			} else {
				ret, err := «a.targetEntity.initialLow»Repo.Get(*p.«a.field.originName»)
				if err != nil {
					panic(err)
				}
				return ret
			}''')
		}
		for(a : e.multiAsses){
			strList.add(
			'''
			ret, _ := «a.targetEntity.initialLow»Repo.FindFromMultiAssTable("«a.tableName»", p.GoenId)
			return ret ''')
		}
		return strList;
	}
	static private def generateSetterBodies(ZEntity e){
		var strList = new ArrayList<String>();
		for(a : e.basicFields){
			strList.add(
			'''
			p.«a.member.originName» = «a.member.initialLow» 
			p.AddBasicFieldChange("«a.member.underline»")
			«e.entityName.initialLow»Repo.AddInQueue(p)''')
		}
		for(a : e.enumFields){
			strList.add('''
			p.«a.member.originName» = «a.member.initialLow» 
			p.AddBasicFieldChange("«a.member.underline»")
			«e.entityName.initialLow»Repo.AddInQueue(p)''')
		}
		for(a : e.singleAsses){
			strList.add(
			'''
			id := «a.targetEntity.initialLow»Repo.GetGoenId(«a.targetEntity.initialLow»)
			p.«a.field.originName» = &id
			p.AddAssFieldChange("«a.field.underline»")
			«e.entityName.initialLow»Repo.AddInQueue(p)''')
		}
		for(a : e.multiAsses){
			strList.add(
			'''
			p.AddMultiAssChange(entityRepo.Include, "«a.tableName»", «a.targetEntity.initialLow»Repo.GetGoenId(«a.targetEntity.initialLow»))
			«e.entityName.initialLow»Repo.AddInQueue(p)''')
			strList.add(
			'''
			p.AddMultiAssChange(entityRepo.Exclude, "«a.tableName»", «a.targetEntity.initialLow»Repo.GetGoenId(«a.targetEntity.initialLow»))
			«e.entityName.initialLow»Repo.AddInQueue(p)''')
		
		}
		return strList;
	}
	static private def generateSetterDeclares(ZEntity e){
		var strList = new ArrayList<String>();
		for(a : e.basicFields){
			strList.add('''Set«a.member.originName» («a.member.initialLow» «a.type.goName») ''')
		}
		for(a : e.enumFields){
			strList.add('''Set«a.member.originName» («a.member.initialLow» «a.type.goName») ''')
		}
		for(a : e.singleAsses){
			strList.add('''Set«a.originName» («a.targetEntity.initialLow» «a.targetEntity.originName») ''')
		}
		for(a : e.multiAsses){
			strList.add('''Add«a.originName» («a.targetEntity.initialLow» «a.targetEntity.originName») ''')
			strList.add('''Remove«a.originName» («a.targetEntity.initialLow» «a.targetEntity.originName») ''')
		}
		return strList;
	}
	
	static def generateInterface(ZEntity e) {
		'''
		type «e.entityName.originName» interface{
			«IF e.parentEntity !== null»
			«e.parentEntity.originName»
			«ENDIF»
			«FOR declare : generateGetterDeclares(e)»
			«declare»
			«ENDFOR»
			«FOR declare : generateSetterDeclares(e)»
			«declare»
			«ENDFOR»
		}
		
		'''
	}
	static def generateStruct(ZEntity e) {
		'''
		type «e.entityName.originName»Entity struct{
			«IF e.isBaseEntity == false && e.parentEntity === null»
			entityRepo.Entity
			«ELSEIF e.parentEntity !== null»
			«e.parentEntity.originName»Entity
			entityRepo.FieldChange
			«ELSEIF e.isBaseEntity == true»
			entityRepo.BasicEntity
			«ENDIF»
			
			«FOR a : e.basicFields»
			«a.member.originName» «a.type.goName» `db:"«a.member.underline»"`
			«ENDFOR»
			«FOR a : e.enumFields»
			«a.member.originName» «a.type.goName» `db:"«a.member.underline»"`
			«ENDFOR»
			«FOR a : e.singleAsses»
			«a.field.originName» *int `db:"«a.field.underline»"`
			«ENDFOR»
		}
		'''
	}
	
	static private def generateFuncPrefix(ZEntity e){
		'''func (p *«e.entityName.originName»Entity)'''
	}
	static def generateOtherImplements(ZEntity e) {
		'''
		«IF e.parentEntity !== null»
		«generateFuncPrefix(e)» GetParentEntity() entityRepo.EntityForInheritRepo {
			return &p.«e.parentEntity.originName»Entity
		}
		
		«ENDIF»
		'''
	}
	
	static class Func{
		public String declare;
		public String body;
	}
	static def generateSetters(ZEntity e) {
		var funcList = new ArrayList<Func>();
		var dList = generateSetterDeclares(e);
		var bList = generateSetterBodies(e);
		for(var i = 0; i < dList.length(); i++  ){
			var b = bList.get(i);
			var d = dList.get(i);
			var func = new Func();
			func.body = b;
			func.declare = d;
			funcList.add(func);
		}
		'''
		«FOR func : funcList»
		«generateFuncPrefix(e)» «func.declare» {
			«func.body»
		}
		«ENDFOR»
		'''
	}
	static def generateGetters(ZEntity e){
		var funcList = new ArrayList<Func>();
		var dList = generateGetterDeclares(e);
		var bList = generateGetterBodies(e);
		for(var i = 0; i < dList.length(); i++  ){
			var b = bList.get(i);
			var d = dList.get(i);
			var func = new Func();
			func.body = b;
			func.declare = d;
			funcList.add(func);
		}
		'''
		«FOR func : funcList»
		«generateFuncPrefix(e)» «func.declare» {
			«func.body»
		}
		«ENDFOR»
		'''
	}
	
	
}