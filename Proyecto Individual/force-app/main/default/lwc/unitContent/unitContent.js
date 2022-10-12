import { LightningElement, wire, api, track } from 'lwc';
import { MessageContext, subscribe, publish } from 'lightning/messageService';
import getunitwrapper from '@salesforce/apex/UnitService.getUnitWrapper';
import registerUnitResponse from '@salesforce/apex/UnitService.registerUnitResponse';
import searchUnit from '@salesforce/apex/UnitService.searchUnit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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

   @wire(MessageContext)
    messageContext;

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
        }

    }
    @track
    optionSelected = [];
    optionSelectedjson = {};
    answerSelected(event) {

        console.log(JSON.stringify(event.detail) + 'detail event');
        this.optionSelectedjson[event.detail.questionId] = event.detail.optionId;
        console.log('objeto' + JSON.stringify(this.optionSelectedjson));
        this.optionSelected = Object.values(this.optionSelectedjson);
        console.log('arraypadre' + this.optionSelected);
    }

 
    handleSubmit(event) {
        console.log('Entré');
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
                        if(resultado.Status__c == 'Success'){
                            const toast = new ShowToastEvent({
                                title: 'Resultado',
                                message: '¡Felicitaciones, usted es un Genio!',
                            });
                            this.dispatchEvent(toast);
                        }else if((resultado.Status__c == 'Fail')){
                            const toast = new ShowToastEvent({
                                title: 'Resultado',
                                message: '¡No se desanime, Vuelva a intentarlo :)!'
                            });
                            this.dispatchEvent(toast);
                        }
                    })
                    .catch((error) => {
                        console.log(error);
                    })
                }
            })
            .catch((error) => {
                console.log(error);
            })
         }

}

