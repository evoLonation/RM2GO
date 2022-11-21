package com.rm2pt.generator.golangclassgenerate.serviceGen

import java.util.Map
import java.util.Collection
import net.mydreamy.requirementmodel.rEMODEL.Service
import java.util.HashMap

class OperationDomain {
	// first String is contract name , second is service name
	Map<String, String> variableMap = new HashMap<String ,String>() ;
	def findService(String operationName){
		return variableMap.get(operationName);
	}
	new (Collection<Service> services){
		for(service : services){
			for(operation : service.operation){
				variableMap.put(operation.name, service.name)
			}		
		}
	}
}