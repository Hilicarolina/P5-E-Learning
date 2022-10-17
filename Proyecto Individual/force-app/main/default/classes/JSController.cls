
// Feedback : Esta clase ya se encuentra dentro de el unit service con su respectivo método por lo que no sería necesario aislarla

public without sharing class JSController {
    @AuraEnabled(cacheable=true)
    public static UnitService.TrailWrapper getTrail(Id trailId) {
        return UnitService.getTrailWrapper(trailId);
    }

  }
