package com.rm2pt.generator.golangclassgenerate.serviceGen

import net.mydreamy.requirementmodel.rEMODEL.AtomicExpression
import net.mydreamy.requirementmodel.rEMODEL.LeftSubAtomicExpression
import net.mydreamy.requirementmodel.rEMODEL.StandardOperationExpCS
import net.mydreamy.requirementmodel.rEMODEL.VariableExpCS
import net.mydreamy.requirementmodel.rEMODEL.PredefineOp
import net.mydreamy.requirementmodel.rEMODEL.StandardNavigationCallExpCS
import net.mydreamy.requirementmodel.rEMODEL.StandardCollectionOperation
import net.mydreamy.requirementmodel.rEMODEL.RightSubAtomicExpression
import net.mydreamy.requirementmodel.rEMODEL.PropertyCallExpCS
import net.mydreamy.requirementmodel.rEMODEL.BooleanLiteralExpCS
import net.mydreamy.requirementmodel.rEMODEL.PrimitiveLiteralExpCS
import net.mydreamy.requirementmodel.rEMODEL.Precondition
import net.mydreamy.requirementmodel.rEMODEL.LogicFormulaExpCS
import org.eclipse.emf.ecore.resource.Resource
import java.util.ArrayList
import net.mydreamy.requirementmodel.rEMODEL.Definition
import net.mydreamy.requirementmodel.rEMODEL.VariableDeclarationCS
import net.mydreamy.requirementmodel.rEMODEL.IteratorExpCS
import net.mydreamy.requirementmodel.rEMODEL.ClassiferCallExpCS
import net.mydreamy.requirementmodel.rEMODEL.FeatureCallExpCS
import net.mydreamy.requirementmodel.rEMODEL.CallExpCS
import java.util.List
import net.mydreamy.requirementmodel.rEMODEL.NestedExpCS
import org.eclipse.emf.ecore.EObject
import net.mydreamy.requirementmodel.rEMODEL.StandardNoneParameterOperation
import net.mydreamy.requirementmodel.rEMODEL.StandardDateOperation
import net.mydreamy.requirementmodel.rEMODEL.Contract
import net.mydreamy.requirementmodel.rEMODEL.Postcondition
import net.mydreamy.requirementmodel.rEMODEL.LetExpCS
import java.util.HashMap
import java.util.Map
import net.mydreamy.requirementmodel.rEMODEL.EntityType
import net.mydreamy.requirementmodel.rEMODEL.TypeCS
import net.mydreamy.requirementmodel.rEMODEL.CollectionTypeCS
import net.mydreamy.requirementmodel.rEMODEL.Entity
import net.mydreamy.requirementmodel.rEMODEL.Attribute
import net.mydreamy.requirementmodel.rEMODEL.Service
import net.mydreamy.requirementmodel.rEMODEL.OCLExpressionCS
import com.rm2pt.generator.golangclassgenerate.Tool
import net.mydreamy.requirementmodel.rEMODEL.EnumLiteralExpCS
import net.mydreamy.requirementmodel.rEMODEL.OperationCallExpCS
import net.mydreamy.requirementmodel.rEMODEL.PrimitiveTypeCS
import java.util.Set

class ContractGenerator {
	Contract contract;
	ServiceGenerator serviceGen;
	VariableDomain variables;
	OperationDomain operationDomain;
	Set<String> importSet;
	new (Contract contract, ServiceGenerator service, OperationDomain operationDomain, Set<String> importSet){
		this.contract = contract;
		serviceGen = service;
		this.operationDomain = operationDomain;
		variables = new VariableDomain();
		// 向importSet中添加本contract需要的import语句
		this.importSet = importSet;
		if(contract.op.parameter !== null){
			for(vari : contract.op.parameter){
				variables.add(vari.name, vari.type)
			}
		}
		if(contract.def !== null){
			for(vari : contract.def.variable){
				variables.add(vari)
			}
		}
		if(contract.post !== null && contract.post.oclexp instanceof LetExpCS){
			for(vari : (contract.post.oclexp as LetExpCS).variable){
				variables.add(vari)
			}
		}
	}
	
	def getName(){
		return contract.op.name
	}
	
	def generate(){
//		if(serviceGen.isSystemLevel()){
//			'''
//			func «name» («FOR para : contract.op.parameter SEPARATOR ','»«para.name» «generateType(para.type)» «ENDFOR») (ret OperationResult[«generateType(contract.op.returnType)»]){
//				defer func() {
//					if err := entityRepo.Saver.Save(); err != nil {
//						ret.Err = NewErrPostCondition(err)
//						return
//					}
//				}()
//				
//				«generateDefinition()»
//				«generatePrecondition()»
//				«generatePostcondition()»
//				
//				return
//			}
//			'''
//		}else{
			'''
			func (p *«serviceGen.name») «name» («FOR para : contract.op.parameter SEPARATOR ','»«para.name» «generateType(para.type)» «ENDFOR») (ret OperationResult[«generateType(contract.op.returnType)»]){
				defer func() {
					if err := entityRepo.Saver.Save(); err != nil {
						ret.Err = NewErrPostCondition(err)
						return
					}
				}()
				
				«generateDefinition()»
				«generatePrecondition()»
				«generatePostcondition()»
				
				return
			}
			'''
//		}
		
	}
	def generateDefinition(){
		if(contract.def === null){
			return ""
		}
		var ret = 
		'''
		//definition
		'''
//		System.out.println("defi is" + defi);
		for(vari : contract.def.variable){
			ret += 
			'''
			«generateDeclaration(vari)»
			'''
		}
		return ret
	}
	def generatePrecondition(){
		if(contract.pre === null){
			return ""
		}
		'''
		// precondition
		if!(
			«generateValue(contract.pre.oclexp)»){
			ret.Err = ErrPreConditionUnsatisfied
			return
		}
		'''
	}
	def generatePostcondition(){
		if(contract.post === null){
			return ""
		}
		switch(exp : contract.post.oclexp){
			LogicFormulaExpCS: {
				generateAction(exp)
			}
			LetExpCS: {
				'''
				«FOR v : exp.variable»
				«generateDeclaration(v)»
				«ENDFOR»
				«generateAction(exp.inExpression)»
				'''
			}
		}
	}
	def String generateAction(EObject exp){
		switch(exp){
			LogicFormulaExpCS: {
				// 必须全是and
				for(co : exp.connector){
					if(!co.equals("and")){
//					if(co !== "and"){
						return "goenUndefined!"
					}
				}
				'''
				«FOR atomic : exp.atomicexp»
				«generateAction(atomic)»
				«ENDFOR»
				'''
			}
			AtomicExpression: {
				if(exp.infixop === null){
					generateAction(exp.leftside)
					// include
					// allinstance and multiass
					// oclisnew
					// isequal	
				}else if(exp.infixop.equals("=")){
					var value = "";
					if(exp.exp === null){
						value = generateValue(exp.rightside)
					}else{
						value = generateValue(exp.rightside, exp.op, exp.exp)
					}
					switch(left : exp.leftside){
						// item.barcode
						PropertyCallExpCS:{
							if(!left.name.symbol.equals("self")){
								'''«generateValue(left.name)».Set«left.attribute»(«value»)'''
							}else{
								'''«generateValue(left.attribute)» = «value»'''
							}
						}
						// currentsale
						default: {
							'''«generateValue(left)» = «generateValue(value)»'''
						}
					}
				}else {
					"goenUndefined"
				}
			}
			StandardOperationExpCS : {
				switch(predefinedop : exp.predefinedop){
					StandardNoneParameterOperation :{
						switch(predefinedop.name){
							case "oclIsNew()" : '''«generateValue(exp.object)» = «generateRepo(findVariableType(exp.object.symbol))».New()'''
						}
					}
					StandardDateOperation:{
						switch(predefinedop.name){
							case "isEqual" :   '''«generateValue(exp.object)».Set«generateValue(exp.property)»(«generateValue(predefinedop.object)»)'''
						}
					}
					default : "goenUndefined!"
				}
			}
			
			StandardNavigationCallExpCS : {
				if(exp.propertycall !== null && exp.classifercall === null){
					var property = exp.propertycall
					switch(exp.standardOP.name){
						case "includes": 
							generateValue(property.name) + ".Add" + property.attribute + "(" + generateValue(exp.standardOP.object) +")"
						case "excludes" : 
							generateValue(property.name) + ".Remove" + property.attribute + "(" + generateValue(exp.standardOP.object) +")"
						default : "goenUndefined!"
					}
				}else if(exp.propertycall === null && exp.classifercall !== null && exp.classifercall.op == "allInstance()"){
					var classifer = exp.classifercall
					switch(exp.standardOP.name){
						case "includes": 
							"entity." + classifer.entity + "Repo.AddInAllInstance" + "(" + exp.standardOP.object +")"
						case "excludes" : 
							"entity." + classifer.entity + "Repo.RemoveFromAllInstance" + "(" + exp.standardOP.object +")"
						default : "goenUndefined!"
					}
				}else {
					"goenUndefined!"
				}
			}
			
			
		}
	}
	
	def String generateValue(EObject exp){
		switch(exp){
			// 只有left
			NestedExpCS: '''(«generateValue(exp.nestedExpression)»)''' 
			LogicFormulaExpCS: {
				if(exp.connector === null){
					generateValue(exp.atomicexp.get(0))
				}else{
					var ret = "";
					for(var i = 0; i < exp.connector.length(); i++){
						var connector = switch(exp.connector.get(i)){
							case "and" : "&&"
							case "or" : "||"
							default : "goenUndefined"
						}
						ret += 
							'''«generateValue(exp.atomicexp.get(i))» «connector»'''
					}
					ret += 
					'''«generateValue(exp.atomicexp.last())»'''
					
					return ret
				}
			}
			AtomicExpression: {
				if(exp.infixop === null){
					generateValue(exp.leftside)
				}else{
					var op = switch(exp.infixop){
						case "=" : "=="
						default: exp.infixop
					}
					var value = "";
					if(exp.exp === null){
						value = generateValue(exp.rightside)
					}else{
						value = generateValue(exp.rightside, exp.op, exp.exp)
					}
					'''«generateValue(exp.leftside)» «op» «value»'''
				}
			}
			VariableExpCS : generateValue(exp.symbol)
			PropertyCallExpCS : '''«generateValue(exp.name)».Get«exp.attribute»()'''
			PrimitiveLiteralExpCS : exp.symbol
			EnumLiteralExpCS: "entity." + exp.enumname + exp.eunmitem
			StandardOperationExpCS :{
				switch(exp.predefinedop.name){
					case "oclIsUndefined()" : '''(«generateValue(exp.object)» == nil)'''
					case "sum()" : {
						importSet.add("\"Cocome/util\"")
						'''util.Sum(«generateValue(exp.object)»)'''
					}
					default : "goenUndefined!"
				}
			}
			StandardNavigationCallExpCS : {
				if(exp.propertycall === null && exp.classifercall !== null && exp.classifercall.op == "allInstance()"){
					var classifer = exp.classifercall
					switch(exp.standardOP.name){
						case "includes": 
							"entity." + classifer.entity + "Repo.IsInAllInstance" + "(" + exp.standardOP.object +")"
						default : "goenUndefined!"
					}
				}else {
					"goenUndefined!"
				}
			}
			ClassiferCallExpCS: {
				System.out.println("is classifer!!!!!!!!!!!")
				if(exp.op.equals("allInstance()")){
					'''«generateRepo(exp.entity)».GetAll()'''
				}else{
					"goenUndefined"
				}
			}
			OperationCallExpCS: {
				'''«operationDomain.findService(exp.name)»Instance.«exp.name»(«FOR param: exp.parameters SEPARATOR ','»«generateValue(param.object)»«ENDFOR»).Value'''
			}
			IteratorExpCS: {
				switch(exp.iterator){
					case "any" : 
						switch(call : exp.objectCall){
						ClassiferCallExpCS: {
							switch(subexp : exp.exp){
							LogicFormulaExpCS: 
								switch(atomicexp : subexp.atomicexp.get(0)){
								AtomicExpression:
									if(atomicexp.infixop == "=" && atomicexp.leftside instanceof PropertyCallExpCS){
										'''«generateRepo(call.entity)».GetFromAllInstanceBy("«Tool.camelToUnderScore((atomicexp.leftside as PropertyCallExpCS).attribute)»", «generateValue(atomicexp.rightside)»)'''
									}
									
								}
							
							}
						}
						default : "goenUndefined!"
						}
					case "select" : 
						switch(call : exp.objectCall){
						ClassiferCallExpCS: {
							switch(subexp : exp.exp){
							LogicFormulaExpCS: 
								switch(atomicexp : subexp.atomicexp.get(0)){
								AtomicExpression:
									if(atomicexp.infixop == "=" && atomicexp.leftside instanceof PropertyCallExpCS){
										'''«generateRepo(call.entity)».FindFromAllInstanceBy("«Tool.camelToUnderScore((atomicexp.leftside as PropertyCallExpCS).attribute)»", «generateValue(atomicexp.rightside)»)'''
									}
									
								}
							
							}
						}
						default : "goenUndefined!"
						}
					case "collect" :{
						if(		exp.varibles.length() == 1 && 
								exp.varibles.get(0).type instanceof EntityType &&
								exp.exp instanceof LogicFormulaExpCS &&
								(exp.exp as LogicFormulaExpCS).atomicexp.length() == 1 &&
								(exp.exp as LogicFormulaExpCS).atomicexp.get(0) instanceof AtomicExpression &&
								((exp.exp as LogicFormulaExpCS).atomicexp.get(0) as AtomicExpression).infixop === null &&
								((exp.exp as LogicFormulaExpCS).atomicexp.get(0) as AtomicExpression).leftside instanceof PropertyCallExpCS){
							var attribute = (((exp.exp as LogicFormulaExpCS).atomicexp.get(0) as AtomicExpression).leftside as PropertyCallExpCS).attribute
							var type = exp.varibles.get(0).type as EntityType
							System.out.println("attribute : "+ attribute)
							System.out.println("type: " + type)
							importSet.add("\"Cocome/util\"")
							'''util.Collect(«generateValue(exp.simpleCall)», func(«FOR vari : exp.varibles»«generateFuncParam(vari)»«ENDFOR») «generateType(findAttributeType(type, attribute))» {return «generateValue(exp.exp)»} )'''
						}
						
						
						
					}
				
				}
			}
		}
	}
	def String generateValue(String symbol){
		switch(symbol){
			case "self" : ""
			case "result" : "ret.Value"
			case "Now" : {
				importSet.add("\"time\"")
				"time.Now()"	
			}
			default:  {
				// 如果是TempProperty则需要添加p.前缀
				if(serviceGen.tempProperties.findType(symbol) !== null && !serviceGen.isSystemLevel()){
					"p." + symbol
				}else{
					symbol
				}
			}
		}
	}
	
	
	
	def String generateDeclaration(VariableDeclarationCS dec){
		'''var «dec.name» «generateType(dec.type)» «IF dec.initExpression!==null» = «generateValue(dec.initExpression)»«ENDIF»'''	
	}
	
	def String generateValue(RightSubAtomicExpression left, String op, AtomicExpression exp){
		System.out.println("in generateValue 2 param")
		
		var leftType = findExpType(left);
		var rightType = findExpType(exp);
		System.out.println("leftType is" + leftType +" and rightType is" + rightType)
		if(leftType instanceof PrimitiveTypeCS && rightType instanceof PrimitiveTypeCS){
			System.out.println("leftType and rightType all PrimitiveTypeCS")
			var lname = (leftType as PrimitiveTypeCS).name;
			var rname = (rightType as PrimitiveTypeCS).name;
			if(lname.equals("Real") && rname.equals("Integer")){
				return '''«generateValue(left)» «op» float64(«generateValue(exp)»)'''
			}else if(rname.equals("Real") && lname.equals("Integer")){
				return '''float64(«generateValue(left)») «op» «generateValue(exp)»'''
			}
		}
		return '''«generateValue(left)» «op» «generateValue(exp)»'''
	}
	
	def TypeCS findExpType(EObject exp){
		switch(exp){
			AtomicExpression : {
				if(exp.infixop === null){
					findExpType(exp.leftside)
				}
			}
			PropertyCallExpCS: {
				switch(father :findVariableType(exp.name.symbol) ){
					EntityType: return findAttributeType(father, exp.attribute)
				}
			}
			VariableExpCS: findVariableType(exp.symbol)
		}
	}
	def TypeCS findVariableType(String symbol){
		if(variables.findType(symbol) !== null){
			return variables.findType(symbol)
		}else if(serviceGen.tempProperties.findType(symbol) !== null){
			return serviceGen.tempProperties.findType(symbol)
		}else{
			null
		}
	}
	
	def TypeCS findAttributeType(EntityType entity, String attribute){
		for(attr : entity.entity.attributes){
			System.out.println("attr is " + attr)
			if(attr.name.equals(attribute)){
				return attr.type
			}
		}
	}
	
	def String generateType(TypeCS type){
		switch(type){
			EntityType: {
				importSet.add("\"Cocome/entity\"")
				"entity." + Tool.compileGoTypeName(type)
			}
			CollectionTypeCS : {
				switch(type.name.name){
					case "Set":	"[]" + generateType(type.type)
					default : "goenUndefined"
				}
			}
			default : {
				var ret = Tool.compileGoTypeName(type)
				if(ret.equals("time.Time")){
					importSet.add("\"time\"")
				}
				return ret
			}
		}
	}
	
	def generateRepo(TypeCS type){
		switch(type){
			EntityType :  "entity." + Tool.compileGoTypeName(type) + "Repo"
			default : "goenUndefined"
		}
	}
	def generateRepo(String entityName){
		"entity." + entityName + "Repo"	
	}
	def generateFuncParam(VariableDeclarationCS dec) {
		'''«dec.name» «generateType(dec.type)»'''
	}
	
}





