import { LightningElement, wire, api, track } from 'lwc';
import getunitwrapper from '@salesforce/apex/UnitService.getUnitWrapper';
import registerUnitResponse from '@salesforce/apex/UnitService.registerUnitResponse';
import searchUnit from '@salesforce/apex/UnitService.searchUnit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class Unitcontent extends LightningElement {
    @api recordId;

    unit;
    questionList;
    _wireResult;
    subscription = null;
    points;
    name;
    time;
    description;
    preguntas;
    verificationAnswer;
    auxiliarHili;
    pointsEarned;
    optionSelected = [];
    optionSelectedjson = {};
  

   @wire(getunitwrapper, { unitId: '$recordId' })
    unitdata(result) {
        const { data, error } = result;
        this._wireResult = result;
        if (data) {
            this.unit = data.unit;
            this.questionList = data.isCompleted ? undefined : data.QuestionList;
            this.name = this.unit.Name;
            this.points = this.unit.Points__c;
            this.time = this.unit.Time_estimate__c;
            this.description = this.unit.Description__c;
            this.preguntas = data.questions;
            this.auxiliarHili = data.UnitResponses.length > 0 ? true : false;
            this.pointsEarned = data.UnitResponses[0].Points__c;
        }else if (error) {
            console.log('data.error')
            console.log(error)
        }

    }
   
    
    answerSelected(event) {
        console.log(JSON.stringify(event.detail) + 'detail event');
        this.optionSelectedjson[event.detail.questionId] = event.detail.optionId;
        console.log('objeto' + JSON.stringify(this.optionSelectedjson));
        this.optionSelected = Object.values(this.optionSelectedjson);
        console.log('arraypadre' + this.optionSelected);
    }



   @api
   async refresh() {
          await refreshApex(this._wireResult);
      }
    

    handleSubmit(event) {
        registerUnitResponse({
                unitId: this.recordId,
                jsonAnswer: JSON.stringify(this.optionSelectedjson)
            })
            .then(result =>{
                if(result!=''){
                    searchUnit({
                        unidadId:result
                    })
                    .then(resultado => {
                        console.log('Unidad creada:'+resultado);
                        if(resultado.Status__c == 'Success'){
                            this.auxiliarHili=true;
                            this.pointsEarned=resultado.Points__c;
                                const toast = new ShowToastEvent({
                                title: 'Resultado',
                                message: '¡Felicitaciones, usted es un Genio!',
                                variant:'success'
                            });
                            this.dispatchEvent(toast);
                         return this.refresh();
                        }else if((resultado.Status__c == 'Fail')){
                            const toast = new ShowToastEvent({
                                title: 'Resultado',
                                message: '¡No se desanime, Vuelva a intentarlo :)!',
                                variant:'error'
                                });
                                this.dispatchEvent(toast);
                        }
                    })
                    .catch((error) => {
                        console.log(error);
                    })
                    /* .finally(() => {
                        this.dispatchEvent(toast);
                    }); */
                }
            })
            .catch((error) => {
                console.log(error);
            })
            
         }

}

