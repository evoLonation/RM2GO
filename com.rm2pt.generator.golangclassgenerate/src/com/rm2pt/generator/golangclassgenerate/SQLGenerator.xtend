package com.rm2pt.generator.golangclassgenerate

import java.util.Collection
import java.util.List

class SQLGenerator {
	
	
	static def generate(Collection<ZEntity> entities) {
		'''
		«FOR e : entities»
		«compileCreateTable(e)»
		«ENDFOR»
		«FOR e : entities»
		«compileAlterTable(e)»
		«ENDFOR»
		'''
	}
	
	
	static def compileCreateTable(ZEntity e) {
		'''
		create table «e.entityName.underline»
		(
			«compileCreateTableItems(e)»
		);
		
		«FOR ass : e.multiAsses»
		create table «ass.tableName»
		(
			owner_goen_id      int,
		    possession_goen_id int,
		    primary key (owner_goen_id, possession_goen_id)
		);
		
		«ENDFOR»
		'''
	}
	static private def compileCreateTableItems(ZEntity e) {
		Tool.removeComma('''
			goen_id                  int primary key,
			«IF e.parentEntity === null »
			goen_in_all_instance     bool not null default (false),
			«ENDIF»
			«IF e.isBaseEntity && e.parentEntity === null »
			goen_inherit_type    int   not null default (0),
			«ENDIF»
			«FOR field: e.basicFields»
			«field.member.underline» «field.type.sqlName» «field.type.sqlConstraint»,
			«ENDFOR»
			«FOR field: e.enumFields»
				«field.member.underline» int not null default (0), #枚举类型 
			«ENDFOR»
			«FOR field: e.singleAsses»
				«field.field.underline» int, 
			«ENDFOR»
		''') + 
		'''	
		
		'''	
	}
	static def compileAlterTable(ZEntity e) {
		'''
		«IF e.singleAsses.length() != 0 || e.parentEntity !== null»
		alter table «e.entityName.underline»
		«compileAlterTableItems(e)»
		«ENDIF»
		
		«FOR multiAss : e.multiAsses»
		alter table «multiAss.tableName»
			add constraint foreign key (owner_goen_id) references «e.entityName.underline» (goen_id) on delete cascade,
		    add constraint foreign key (possession_goen_id) references «multiAss.targetEntity.underline» (goen_id) on delete cascade;
		
		«ENDFOR»
		'''
	}
	static private def compileAlterTableItems(ZEntity e){
		Tool.removeComma('''
		«FOR ass: e.singleAsses»	
			add constraint foreign key («ass.field.underline») references «ass.targetEntity.underline»(goen_id) on delete set null,
		«ENDFOR»
		«IF e.parentEntity !== null»
			add constraint foreign key (goen_id) references «e.parentEntity.underline» (goen_id) on delete cascade,
		«ENDIF»
		''') + 
		'''
		;
		'''
	}
}