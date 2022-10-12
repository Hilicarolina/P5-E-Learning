import { api, LightningElement, wire } from 'lwc';
//import getTrail from '@salesforce/apex/JSController.getTrail';
import getTrail from '@salesforce/apex/UnitService.getTrailWrapper';
export default class TrailView extends LightningElement {
  @api recordId;
   name;
   time;
   description;
   points;
   error = undefined;
   modulos;
   checkmodule;
   checkunit;
   progress;
  
    

    @wire(getTrail, { trailId: '$recordId' })
    trail(Result) {
        const { data, error } = Result;
        if (data) {
            console.log(data);
            this.name = data.trail.Name;
            this.time = data.trail.Time_estimate__c;
            this.description = data.trail.Description__c;
            this.points = data.trail.Points__c;
            this.checkunit = data.passedUnitIds;
            this.progress=Math.round((data.passedUnitIds.length/data.trail.Quantity_unit__c)*100);
            this.modulos = data.modules;
            this.checkmodule = data.passedModuleIds;
            
        } else if (error) {
            this.trailWrapper = undefined;
            this.error = error;
        }

    }
}