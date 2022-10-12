//La única responsabilidad del servicio "UnitService.registerUnitResponse(Id unidad,String json)" es crear los
//registros de la respuesta (setear la respuesta de la unidad con estado “Draft”) y, una vez que se termine de
//crear toda la estructura relacionada (opciones respondidas para cada pregunta), actualizar en la base de datos 
//la respuesta de la unidad al estado “Answered”.

public class UnitService {
  public class CustomException extends Exception{}  
  @AuraEnabled(cacheable=false)
  public static String registerUnitResponse(Id unitId, String jsonAnswer) {
     
      //Método de Apex que me permite crear un punto desde donde deseo revertir la transacción (Roll-Up) si esta falla :
      Savepoint sp = Database.setSavepoint();
      
      //Esta variable es la que registrará la salida del método "registerUnitResponse". Si el registro de respuestas fue
      //exitoso, su valor será "True". 
      //Boolean verify = false;
      String IdUnidad = '';
      try{
        
      //Busco la Unidad correspondiente al parámetro Id desde la base de datos:
      Unit__c unit = [SELECT Module__c, (SELECT Id, Numbers_Of_Tries__c,User__c FROM User_Units__r WHERE User__c =:UserInfo.getUserId() ORDER BY Numbers_Of_Tries__c DESC LIMIT 1),(SELECT Id, Name FROM Questions__r) FROM Unit__c WHERE Id =:unitId];
      
       //La primera Query interna buscará si ya la unidad tiene registros relacionados en el objeto "User_Unit__c"
      //asociado al usuario al que queremos registrar su respuesta.
      
      //La segunda Query interna corresponde a una validación. Esta se hace para, más adelante, iterar sobre
      // las preguntas reales relacionadas a la unidad. Esto lo hacemos para validar que el usuario no esté 
      // enviando respuestas a cualquier pregunta, sino a las preguntas relacionadas con la unidad que está 
      // respondiendo.
      
      //Hacemos una query en el objeto User_Module__c, para traernos el registro padre de la unidad que estamos
      //respondiendo
      User_Module__c moduleResp;
      try{
      moduleResp = [SELECT Id FROM User_Module__c WHERE Module__c = :unit.Module__c AND User__c = :UserInfo.getUserId() AND Status__c = 'In Progress'];
      // La query anterior será null en el caso que estamos respondiendo la primera unidad correspondiente
      // a dicho módulo. Si la Query es "null" procederemos a crear e insertar un Registro en el objeto "User_Module__c" 
      
      
      }
      catch(Exception e){
    
        //Creación e inserción de User_Module__c(Primera unidad respondida)
      moduleResp = new User_Module__c(User__c = userInfo.getUserId(),Module__c = unit.Module__c,Status__c = 'In Progress');
      insert moduleResp;
      
      }
          
     //Una vez pasada por las líneas de arriba, ya tenemos creado el registro en el objeto "Module_Response__c" que será padre
     //por relación "master-detail" del registro "User_Unit__c" que crearemos a continuación.
     // 
     //Creación e inserción de un registro en el objeto "User_Unit__c":
      User_Unit__c unitResp = new User_Unit__c(Unit__c = unitId,User_Module__c = moduleResp.Id,Status__c = 'Draft',User__c= userInfo.getUserId());   
      unitResp.Numbers_Of_Tries__c = !unit.User_Units__r.isEmpty() ? unit.User_Units__r[0].Numbers_Of_Tries__c + 1: 1;
      insert unitResp;
      
      
     //Usaremos la API: "JSON.deserializeStrict(String json, Map<Id,Id>.class". Esta nos ayuda a deserializar el segundo
     //parámetro de entrada del método que es de tipo String pero con forma json. Esto nos permitirá convertir este parámetro
     //en una estructura de dato que será más fácil de manipular en la base, por ejemplo con un Map<Id,Id>.   
    Map<Id, Id> answerMap = (Map<Id, Id>) JSON.deserialize(jsonAnswer,Map<Id, Id>.class);
          
     //Creo y cargo, en el objeto "User_Answer__c", las preguntas que han sido respondidas por el usuario:     
    List<User_Answer__c> questionRespList = new List<User_Answer__c>();
          
     //Iteramos sobre las preguntas reales que pertenecen a la unidad. En este paso verificamos si las preguntas
     //que nos están enviando por parámetro por parámetro (Id de key del Map) son las preguntas reales correspondientes
     // a la unidad que estamos respondiendo.
    for (Question__c question : unit.Questions__r) {
      if (answerMap.containsKey(question.Id)) {
        User_Answer__c questionResp = new User_Answer__c(
          Question__c = question.Id,
          User_Unit__c = unitResp.Id, 
          Answer__c = answerMap.get(question.Id)
        );
        questionRespList.add(questionResp);
      } else {
          //Atrapa el error en caso de que el frontend envíe preguntas que no se corresponden a las preguntas de la unidad.
          //En este caso, inmediatamente se detiene la ejecución y este error es atrapado por el "Catch".
        throw new CustomException('La pregunta no fue respondida y es requerida');
        
      }
    }
    insert questionRespList;
          
    //Actualizamos el campo "Status__c" en el objeto "User_Unit__c"  a 'Answered' para disparar el proceso de evaluación.
    unitResp.Status__c = 'Answered';
    update unitResp;
    //verify = true;
    IdUnidad=unitResp.Id;
  
}
      catch(Exception e){
          //Hacemos un Roll-Up de la transacción (Revertimos cualquier registro que fue insertado o actualizado en las
          //líneas de ejecucíon del "Try":
          Database.rollback(sp);
          throw e;
      }
      //return verify;
      return IdUnidad;
 }
  ////////////////////////////////////////Método que busca unidades dado su Id///////////////////////////
  @AuraEnabled(cacheable=true)
  public static User_Unit__c searchUnit(Id unidadId){
    User_Unit__c unidad= [SELECT Id, Status__c FROM User_Unit__c WHERE Id=:unidadId];
   return unidad;
  }
  
  ////////////////////////////////////////////////Wrapper////////////////////////////////////////////////////
  @AuraEnabled(cacheable=true)
 public static TrailWrapper getTrailWrapper(Id trailId){
     
    ////////////////////Configuración////////////////////
    
    //Trail seleccionado por usuario:
    Trail__c trail = [SELECT Id, Name, Description__c,Points__c,Time_estimate__c,Quantity_unit__c FROM Trail__c WHERE Id=:trailId];
    //Lista de módulos relacionados al Trail seleccionado:
    List<Module__c>modules = getModules(trailId);
  
    //////////////////Transaccionales///////////////////// 
     
     //Carga de module ids completados:
     List<Id> completedModuleIds = getModuleIdsCompleted(trailId);
     //Carga de unit ids completados:
     List<Id> completedUnitIds = getUnitIdsCompleted(trailId);
    
    

 ///////Instanciamos la clase TrailWrapper:
    TrailWrapper trailWrap = new TrailWrapper(trail,modules,completedModuleIds,completedUnitIds);
    return trailWrap;
  }
  
  private static List<Module__c> getModules(Id trailId){
    ///Configuración//
    
    ////////Cargamos la Tabla intermedia que nos permitirá obtener los módulos relacionados al Trail
    //seleccionado por el usuario.
    List<Trail_Module__c>trailModules = [SELECT Id,Trail__c, Module__c,Module__r.Name, Module__r.Points__c FROM Trail_Module__c  WHERE Trail__c=:trailId];
     
    //Ids de módulos relacionados al Trailhead seleccionado.
     Set<Id>moduleIds = new Set<Id>();
     for(Trail_Module__c trailModule : trailModules){
         moduleIds.add(trailModule.Module__c);
     }
    ///////Lista de módulos relacionados al Trailhead seleccionado
    List<Module__c>modules = [SELECT Id, Name, Description__c, Points__c,Time_estimate__c, (SELECT Id, Name,Description__c,Points__c,Time_estimate__c FROM Units__r) FROM Module__c WHERE Id IN : moduleIds];
    return modules;
  }
  
  private static List<Id> getModuleIdsCompleted(Id trailId){
   //Transaccionales//  
     
   //Carga de module ids completados:
   
   //Método alternativo de resolver esto:
     /*Set<Id>completedModuleIds = new Map<Id,Module__c>([SELECT Id From Module__c WHERE Id IN :(SELECT Module__c FROM 
     User_Module__c WHERE Status__c='Completed' AND Module__c IN : moduleIds AND User__c =: UserInfo.getUserId())]).keyset();*/
     
     //Solución:
     List <User_Module__c>moduleResponses = [SELECT Module__c FROM User_Module__c WHERE Status__c='Completed' AND Module__c IN : getModules(trailId) AND User__c =: UserInfo.getUserId()];
     List<Id> completedModuleIds = new List<Id>();
     for(User_Module__c moduleResp:moduleResponses){
      completedModuleIds.add(moduleResp.Module__c);
  }
     return completedModuleIds;
  }
  
  private static List<Id> getUnitIdsCompleted(Id trailId){
    //Transaccional//
    
    //Carga de unit ids completados:
      List <User_Unit__c>unitResponses =[SELECT Unit__c FROM User_Unit__c WHERE Status__c = 'Success' AND Unit__r.Module__c IN : getModules(trailId) AND User__c =: UserInfo.getUserId()];
      List<Id> completedUnitIds = new List<Id>();
     for(User_Unit__c unitResp:unitResponses){
         completedUnitIds.add(unitResp.Unit__c);
     }
      return completedUnitIds;
  }
  @AuraEnabled(cacheable=true)
   public static UnitWrapper getUnitWrapper(Id unitId){
      //Unidad solicitada:
      Unit__c unit = [SELECT Name,Description__c,Points__c,Time_estimate__c FROM Unit__c WHERE Id =: unitId WITH SECURITY_ENFORCED];
      //Listado de preguntas relacionadas a la unidad de la línea de arriba:
      List<Question__c> questions = [SELECT id,Name,Description__c,(SELECT id, Name, Description__c,Is_Correct__c FROM Answers__r)FROM question__c WHERE Unit__c =: unitId WITH SECURITY_ENFORCED];
       
      //Instancia de la clase "UnitWrapper":
      UnitWrapper unitWrap = new UnitWrapper(unit, questions);
      return unitWrap;
  }
  
  
  /////////////Clase TrailWrapper//////////////
 public class TrailWrapper{
    //Configuración
    @AuraEnabled 
    public Trail__c trail; //Trail solicitado.
    @AuraEnabled 
    public List<Module__c> modules; //Módulos det Trail solicitado, con Unidades relacionadas.
    
    //Transaccional
    @AuraEnabled 
    public List<Id> passedModuleIds;//Ids de módulos relacionados al Trail actual en los que el Alumno ya aprobó.
    @AuraEnabled 
    public List<Id> passedUnitIds; //Ids de Unidades relacionadas a módulos del Trail actual que el Alumno ya aprobó.
    
     //Constructor
     public TrailWrapper(Trail__c trail,List<Module__c> modules,List<Id> passedModuleIds,List<Id> passedUnitIds){
         this.trail = trail;
         this.modules= modules;
         this.passedModuleIds = passedModuleIds;
         this.passedUnitIds = passedUnitIds;
        
     }
}
  
  //////////////Clase UnitWrapper///////////////
  public class UnitWrapper {
    @AuraEnabled 
      public Unit__c unit; //Registro de Unidad solicitada
      @AuraEnabled 
      public List <Question__c> questions; //Listado de Preguntas con Opciones relacionadas

      public UnitWrapper (Unit__c unit, List<Question__c> questions){
          this.unit = unit;
          this.questions = questions;
      }
  }
}