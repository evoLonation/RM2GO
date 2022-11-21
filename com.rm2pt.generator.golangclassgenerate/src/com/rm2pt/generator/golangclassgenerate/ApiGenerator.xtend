package com.rm2pt.generator.golangclassgenerate

import net.mydreamy.requirementmodel.rEMODEL.Service
import net.mydreamy.requirementmodel.rEMODEL.Contract
import java.util.Map
import java.util.TreeMap
import java.util.List
import com.rm2pt.generator.golangclassgenerate.Tool
import net.mydreamy.requirementmodel.rEMODEL.Operation

public  class ApiGenerator {
	Map<Service, List<Contract>> contracts;
	
	
	
	new (Map<Service, List<Contract>> contracts){
		this.contracts = contracts;
	}
	
	def generate() {
		'''
		package serviceGen
		
		import (
			"errors"
			"github.com/gin-gonic/gin"
			"net/http"
		)
		
		//该函数返回一个gin.H，gin.H是一个map，存储着键值对，将要返回给请求者
		func errorResponse(err error) gin.H {
			return gin.H{"error": err.Error()}
		}
		
		«generateStartFunc»
		
		«FOR serviceContract : contracts.entrySet»
		«FOR contract : serviceContract.getValue»
		«generateApiFunc(serviceContract.getKey, contract)»
		«ENDFOR»
		«ENDFOR»
		
		'''
	}
	
	def generateStartFunc(){
		var ret = 
		'''
		func Start() error {	
			router := gin.Default()
			var authRoute *gin.RouterGroup
		''';
		for(serviceContract : contracts.entrySet()){
			ret += 
		'''
			authRoute = router.Group("/«serviceContract.getKey().name»")
			'''
			for(contract : serviceContract.getValue()){
				ret += 
		'''
			authRoute.GET("/«contract.op.name»", «contract.op.name»)
			'''
			}
		}
		ret += 
		'''
			return router.Run()
		}
		'''
		return ret
	}
	
	static class Symbol{
		
	}
	def generateApiFunc(Service service, Contract contract){
		'''
		type «contract.op.name»Request struct {
			«FOR parameter : contract.op.parameter»
			«Tool.firstUpperCase(parameter.name)» «Tool.compileGoTypeName(parameter.type)» `json:"«parameter.name»"`
			«ENDFOR»
		}
		
		func «contract.op.name»(ctx *gin.Context) {
			var req «contract.op.name»Request
			if err := ctx.ShouldBindJSON(&req); err != nil {
				//证明请求对于该结构体并不有效
				ctx.JSON(http.StatusBadRequest, errorResponse(err))
				return
			}
			ret := «service.name»Instance.«contract.op.name»(«FOR param : contract.op.parameter SEPARATOR ','»req.«Tool.firstUpperCase(param.name)» «ENDFOR»)
			var errPostCondition *ErrPostCondition
			if errors.Is(ret.Err, ErrPreConditionUnsatisfied) {
				ctx.JSON(http.StatusBadRequest, errorResponse(ret.Err))
				return
			} else if errors.As(ret.Err, &errPostCondition) {
				ctx.JSON(http.StatusInternalServerError, errorResponse(errors.Unwrap(ret.Err)))
				return
			}
			ctx.JSON(http.StatusOK, gin.H{"«Tool.compileGoTypeName(contract.op.returnType)»": ret.Value})
			return
		}
		
		'''
	}
	
}