public without sharing class JSController {
    @AuraEnabled(cacheable=true)
    public static UnitService.TrailWrapper getTrail(Id trailId) {
        return UnitService.getTrailWrapper(trailId);
    }

  }